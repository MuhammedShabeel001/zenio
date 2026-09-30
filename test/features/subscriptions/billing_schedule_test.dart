import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/subscriptions/domain/billing_schedule.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/shared/services/notification_service.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../helpers/test_storage.dart';

SubscriptionModel _sub(DateTime due, String cycle, {int? billingDay}) =>
    SubscriptionModel(
      id: 'netflix',
      title: 'Netflix',
      category: 'Streaming',
      amount: 649,
      currency: 'INR',
      nextBillingDate: due,
      billingCycle: cycle,
      iconName: '🎬',
      billingDay: billingDay,
    );

void main() {
  group('rolledForward', () {
    test('moves an overdue monthly subscription to its next date', () {
      final rolled = rolledForward(
        _sub(DateTime(2026, 6, 15), 'Monthly'),
        DateTime(2026, 9, 29, 18),
      );
      expect(rolled.nextBillingDate, DateTime(2026, 10, 15));
    });

    test('a subscription due today stays due today', () {
      final sub = _sub(DateTime(2026, 9, 29, 8), 'Monthly');
      expect(rolledForward(sub, DateTime(2026, 9, 29, 23)), sub);
    });

    test('renews on the last day of shorter months and returns to the 31st',
        () {
      final february = rolledForward(
        _sub(DateTime(2026, 1, 31), 'Monthly'),
        DateTime(2026, 2, 10),
      );
      expect(february.nextBillingDate, DateTime(2026, 2, 28));
      expect(february.billingDay, 31);

      final march = rolledForward(february, DateTime(2026, 3, 5));
      expect(march.nextBillingDate, DateTime(2026, 3, 31));
    });

    test('uses 29 February in leap years', () {
      final rolled = rolledForward(
        _sub(DateTime(2028, 1, 30), 'Monthly'),
        DateTime(2028, 2, 2),
      );
      expect(rolled.nextBillingDate, DateTime(2028, 2, 29));
    });

    test('weekly and yearly cycles', () {
      expect(
        rolledForward(
          _sub(DateTime(2026, 9, 1), 'Weekly'),
          DateTime(2026, 9, 20),
        ).nextBillingDate,
        DateTime(2026, 9, 22),
      );
      expect(
        rolledForward(_sub(DateTime(2024, 2, 29), 'Yearly'), DateTime(2026, 9))
            .nextBillingDate,
        DateTime(2027, 2, 28),
      );
    });

    test('leaves unknown cycles alone', () {
      final sub = _sub(DateTime(2026), 'Fortnightly');
      expect(rolledForward(sub, DateTime(2026, 9, 29)), sub);
    });
  });

  test('reminder ids are stable across runs', () {
    // Fixed expected values: these must never change between app versions.
    expect(NotificationService.notificationIdFor('netflix'), 1766358123);
    expect(NotificationService.notificationIdFor(''), 0x811c9dc5 & 0x7FFFFFFF);
  });

  test('loading saves rolled-forward billing dates', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final storage = TestStorage.create();
    final overdue = _sub(DateTime(2020, 1, 31), 'Monthly');
    await storage.putKeyValue(
      'subscriptions_list_key_v3',
      jsonEncode([jsonEncode(overdue.toJson())]),
    );
    final container = storage.container();
    await container.read(sqlitePrefsProvider.future);

    container.read(subscriptionsNotifierProvider);
    await container.read(subscriptionsNotifierProvider.notifier).loadData();

    final prefs = SqlitePrefs(storage.open());
    await prefs.init();
    final stored = await prefs.readJsonList(
      'subscriptions_list_key_v3',
      SubscriptionModel.fromJson,
    );
    final today = DateTime.now();
    expect(
      stored.single.nextBillingDate
          .isBefore(DateTime(today.year, today.month, today.day)),
      isFalse,
    );
    expect(stored.single.billingDay, 31);
  });

  test('editing only the price keeps the renewal day', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final storage = TestStorage.create();
    final today = DateTime.now();
    // Renews on the 31st; currently due on a shorter month's last day.
    final shortMonthEnd = DateTime(today.year, today.month + 2, 0);
    final sub = _sub(shortMonthEnd, 'Monthly', billingDay: 31);
    await storage.putKeyValue(
      'subscriptions_list_key_v3',
      jsonEncode([jsonEncode(sub.toJson())]),
    );
    final container = storage.container();
    await container.read(sqlitePrefsProvider.future);
    container.read(subscriptionsNotifierProvider);

    await container
        .read(subscriptionsNotifierProvider.notifier)
        .updateSubscription(sub.copyWith(amount: 799));

    final prefs = SqlitePrefs(storage.open());
    await prefs.init();
    final stored = await prefs.readJsonList(
      'subscriptions_list_key_v3',
      SubscriptionModel.fromJson,
    );
    expect(stored.single.amount, 799);
    expect(stored.single.billingDay, 31);
  });

  group('subscription totals', () {
    SubscriptionModel priced(double amount, String cycle) =>
        _sub(DateTime(2026, 10), cycle).copyWith(amount: amount);

    test('all cycles together are shown as a monthly equivalent', () {
      final subs = [
        priced(120, 'Weekly'), // 120 × 52 / 12 = 520
        priced(649, 'Monthly'),
        priced(1200, 'Yearly'), // 1200 / 12 = 100
      ];

      expect(subscriptionsTotal(subs, 'All'), closeTo(1269, 0.001));
    });

    test('one cycle is shown as its own plain total', () {
      final weekly = [priced(120, 'Weekly'), priced(80, 'Weekly')];

      expect(subscriptionsTotal(weekly, 'Weekly'), 200);
    });

    test('daily and unknown cycles', () {
      expect(monthlyEquivalent(priced(12, 'Daily')), closeTo(365, 0.001));
      expect(monthlyEquivalent(priced(99, 'Fortnightly')), 99);
    });
  });
}
