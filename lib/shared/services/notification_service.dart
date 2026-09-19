import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/shared/utils/formatters.dart';

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

  /// Initialize notification settings and timezone data
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked with payload: ${response.payload}');
      },
    );

    // Create Android notification channel and request permissions
    if (!kIsWeb) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );
        try {
          await androidPlugin.requestNotificationsPermission();
        } catch (_) {}
      }

      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        try {
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (_) {}
      }
    }

    _initialized = true;
  }

  /// Request runtime notification permissions
  Future<bool?> requestPermissions() async {
    if (kIsWeb) return false;

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
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

  /// Helper to derive a positive 32-bit integer ID from a subscription ID
  int _getNotificationId(String subscriptionId) {
    return subscriptionId.hashCode & 0x7FFFFFFF;
  }

  /// Schedule a renewal reminder notification for a subscription
  Future<void> scheduleSubscriptionReminder(SubscriptionModel subscription) async {
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
      debugPrint('Scheduled subscription notification for ${subscription.title} at $tzDateTime');
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
        debugPrint('Failed to schedule notification: $e2');
      }
    }
  }

  /// Cancel a scheduled subscription notification
  Future<void> cancelSubscriptionReminder(String subscriptionId) async {
    final id = _getNotificationId(subscriptionId);
    await _notificationsPlugin.cancel(id);
  }

  /// Reschedule reminders for an entire list of subscriptions
  Future<void> rescheduleAllSubscriptionReminders(
    List<SubscriptionModel> subscriptions,
  ) async {
    for (final sub in subscriptions) {
      await scheduleSubscriptionReminder(sub);
    }
  }
}
