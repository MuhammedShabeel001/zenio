import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
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

  /// A positive 31-bit notification id derived from a subscription id. Uses
  /// FNV-1a because `String.hashCode` is not guaranteed to stay the same
  /// between app runs.
  @visibleForTesting
  static int notificationIdFor(String subscriptionId) {
    var hash = 0x811c9dc5;
    for (final unit in subscriptionId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    // Android notification ids must fit a signed 32-bit int.
    return hash & 0x7FFFFFFF;
  }

  int _getNotificationId(String subscriptionId) =>
      notificationIdFor(subscriptionId);

  /// Schedule a renewal reminder notification for a subscription
  Future<void> scheduleSubscriptionReminder(
      SubscriptionModel subscription,) async {
    if (kIsWeb) return;
    await initialize();

    final id = _getNotificationId(subscription.id);
    // Cancel any previous reminder for this subscription
    await _notificationsPlugin.cancel(id);

    final now = DateTime.now();
    var reminderTime = DateTime(
      subscription.nextBillingDate.year,
      subscription.nextBillingDate.month,
      subscription.nextBillingDate.day - 1,
      9,
    );

    // If 1 day before at 9:00 AM is already in the past, try the due date itself at 9:00 AM
    if (reminderTime.isBefore(now)) {
      reminderTime = DateTime(
        subscription.nextBillingDate.year,
        subscription.nextBillingDate.month,
        subscription.nextBillingDate.day,
        9,
      );
    }

    // If still in the past, nothing to schedule for this cycle
    if (reminderTime.isBefore(now)) {
      return;
    }

    final tzDateTime = tz.TZDateTime.from(reminderTime, tz.local);
    final formattedDate =
        DateFormat.yMMMd().format(subscription.nextBillingDate);
    final formattedAmount =
        '${subscription.currency} ${AppNumberFormat.formatAmount(subscription.amount, alwaysShowDecimals: true)}';

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

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        'Subscription Due: ${subscription.title}',
        'Your ${subscription.title} subscription ($formattedAmount) is due for renewal on $formattedDate.',
        tzDateTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: subscription.id,
      );
      if (kDebugMode) {
        debugPrint('Scheduled subscription reminder $id at $tzDateTime');
      }
    } catch (e) {
      // Fallback without exact alarm if permission is restricted
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          'Subscription Due: ${subscription.title}',
          'Your ${subscription.title} subscription ($formattedAmount) is due for renewal on $formattedDate.',
          tzDateTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: subscription.id,
        );
      } catch (e2) {
        if (kDebugMode) debugPrint('Failed to schedule notification: $e2');
      }
    }
  }

  /// Cancel a scheduled subscription notification
  Future<void> cancelSubscriptionReminder(String subscriptionId) async {
    final id = _getNotificationId(subscriptionId);
    await _notificationsPlugin.cancel(id);
  }

  /// Makes the scheduled reminders match [subscriptions]: one reminder per
  /// subscription, and none for subscriptions that no longer exist.
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
      final ids = {for (final sub in subscriptions) sub.id};
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      for (final request in pending) {
        // Also drops reminders scheduled under an older id for the same
        // subscription, so it is never reminded twice.
        final payload = request.payload;
        if (payload == null ||
            !ids.contains(payload) ||
            request.id != _getNotificationId(payload)) {
          await _notificationsPlugin.cancel(request.id);
        }
      }
      for (final sub in subscriptions) {
        await scheduleSubscriptionReminder(sub);
      }
    } catch (error) {
      // Reminders are best effort; they are synced again on the next launch.
      if (kDebugMode) debugPrint('Could not sync reminders: $error');
    }
  }
}
