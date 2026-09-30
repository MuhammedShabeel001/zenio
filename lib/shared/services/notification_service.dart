import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/domain/reminder_schedule.dart';
import 'package:zenio/shared/utils/currency_display.dart';
import 'package:zenio/shared/utils/formatters.dart';
import 'package:zenio/shared/utils/serial_task_queue.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'subscription_reminders';
  static const String _channelName = 'Subscription Reminders';
  static const String _channelDesc =
      'Timely reminders for upcoming subscription renewals and due dates';

  final StreamController<String> _reminderTaps =
      StreamController<String>.broadcast();
  String? _launchReminderId;

  /// Subscription ids of reminders the user taps while the app is running.
  Stream<String> get reminderTaps => _reminderTaps.stream;

  /// The subscription id of the reminder that launched the app, if any.
  /// Returned once.
  String? takeLaunchReminder() {
    final id = _launchReminderId;
    _launchReminderId = null;
    return id;
  }

  /// Sets up the plugin, time zones and the Android channel. Asks for no
  /// permission: that happens when the user first adds a subscription (see
  /// [requestPermissions]).
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // The iOS defaults would ask for permission on launch.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final id = response.payload;
        if (id != null && id.isNotEmpty) _reminderTaps.add(id);
      },
    );

    if (!kIsWeb) {
      try {
        final launch =
            await _notificationsPlugin.getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp ?? false) {
          _launchReminderId = launch!.notificationResponse?.payload;
        }
      } catch (_) {}

      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  /// Request runtime notification permissions
  Future<bool?> requestPermissions() async {
    if (kIsWeb) return false;

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    return true;
  }

  /// The notification id of a subscription's next renewal reminder.
  @visibleForTesting
  static int notificationIdFor(String subscriptionId) =>
      reminderIdFor(subscriptionId);

  /// Schedules [reminder] for [subscription], replacing whatever was
  /// scheduled under the same id.
  Future<void> _scheduleReminder(
    SubscriptionModel subscription,
    PlannedReminder reminder,
  ) async {
    final tzDateTime = tz.TZDateTime.from(reminder.at, tz.local);
    final formattedDate = DateFormat.yMMMd().format(reminder.renewal);
    final formattedAmount =
        '${currencyDisplayCode(subscription.currency)} ${AppNumberFormat.formatAmount(subscription.amount, alwaysShowDecimals: true)}';
    final title = 'Subscription Due: ${subscription.title}';
    final body =
        'Your ${subscription.title} subscription ($formattedAmount) is due for renewal on $formattedDate.';

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Subscription renewal reminder',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    Future<void> schedule(AndroidScheduleMode mode) {
      return _notificationsPlugin.zonedSchedule(
        reminder.id,
        title,
        body,
        tzDateTime,
        details,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // Opens this subscription when tapped.
        payload: subscription.id,
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
      if (kDebugMode) {
        debugPrint('Scheduled subscription reminder ${reminder.id} at $tzDateTime');
      }
    } catch (_) {
      // Fallback without exact alarm if permission is restricted
      try {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (e2) {
        if (kDebugMode) debugPrint('Failed to schedule notification: $e2');
      }
    }
  }

  /// Makes the scheduled reminders match [subscriptions]: reminders for the
  /// next few renewals of each, and none for subscriptions that no longer
  /// exist.
  Future<void> syncSubscriptionReminders(
    List<SubscriptionModel> subscriptions,
  ) {
    // One sync at a time, so an older sync cannot re-add a reminder that a
    // newer one removed.
    return _syncs.run(() => _syncSubscriptionReminders(subscriptions));
  }

  final SerialTaskQueue _syncs = SerialTaskQueue();

  Future<void> _syncSubscriptionReminders(
    List<SubscriptionModel> subscriptions,
  ) async {
    if (kIsWeb) return;
    try {
      await initialize();
      final now = DateTime.now();
      // The next few renewals of each subscription, by notification id.
      final planned = {
        for (final sub in subscriptions)
          for (final reminder in plannedReminders(sub, now))
            reminder.id: (subscription: sub, reminder: reminder),
      };
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      for (final request in pending) {
        // Reminders of deleted subscriptions, renewals no longer ahead and
        // ids from older versions are removed, so nothing arrives twice.
        final plan = planned[request.id];
        if (plan == null || request.payload != plan.subscription.id) {
          await _notificationsPlugin.cancel(request.id);
        }
      }
      for (final plan in planned.values) {
        await _scheduleReminder(plan.subscription, plan.reminder);
      }
    } catch (error) {
      // Reminders are best effort; they are synced again on the next launch.
      if (kDebugMode) debugPrint('Could not sync reminders: $error');
    }
  }
}
