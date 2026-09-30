import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/domain/reminder_schedule.dart';
import 'package:zenio/features/subscriptions/domain/repositories/implementations/subscriptions_repository.dart';
import 'package:zenio/features/subscriptions/domain/repositories/interfaces/i_subscriptions_repository.dart';
import 'package:zenio/shared/services/notification_service.dart';

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

class _CountingSubscriptions implements ISubscriptionsRepository {
  _CountingSubscriptions(this.items);

  final List<SubscriptionModel> items;
  int loads = 0;

  @override
  Future<List<SubscriptionModel>> getSubscriptions() async {
    loads++;
    return items;
  }

  @override
  Future<void> saveSubscriptions(List<SubscriptionModel> subscriptions) async {}

  @override
  Future<double> getSubscriptionsBalance() async => 0;
}

void main() {
  final now = DateTime(2026, 9, 30, 12);

  group('planned reminders', () {
    test('a weekly subscription is reminded of its next three renewals', () {
      final reminders =
          plannedReminders(_sub(DateTime(2026, 10, 2), 'Weekly'), now);

      expect(reminders.map((r) => r.renewal), [
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 9),
        DateTime(2026, 10, 16),
      ]);
      // The day before, at 9 AM.
      expect(reminders.first.at, DateTime(2026, 10, 1, 9));
      expect(reminders.map((r) => r.id).toSet(), hasLength(3));
    });

    test('the next renewal keeps the id reminders always had', () {
      final reminders =
          plannedReminders(_sub(DateTime(2026, 10, 2), 'Weekly'), now);

      expect(
        reminders.first.id,
        NotificationService.notificationIdFor('netflix'),
      );
    });

    test('monthly gets two, yearly one', () {
      expect(
        plannedReminders(_sub(DateTime(2026, 10, 31), 'Monthly'), now)
            .map((r) => r.renewal),
        // Renews on the 31st, or the last day of shorter months.
        [DateTime(2026, 10, 31), DateTime(2026, 11, 30)],
      );
      expect(
        plannedReminders(_sub(DateTime(2027, 1, 5), 'Yearly'), now),
        hasLength(1),
      );
    });

    test('once the day before has passed, the reminder is on the day', () {
      final reminders =
          plannedReminders(_sub(DateTime(2026, 10), 'Monthly'), now);

      // The day before (30 Sep, 9 AM) is already past at noon.
      expect(reminders.first.at, DateTime(2026, 10, 1, 9));
    });

    test('a renewal whose reminder time has passed is skipped', () {
      final reminders =
          plannedReminders(_sub(DateTime(2026, 9, 30), 'Weekly'), now);

      // Today at 9 AM has passed; the next two renewals are still reminded.
      expect(reminders.map((r) => r.renewal), [
        DateTime(2026, 10, 7),
        DateTime(2026, 10, 14),
      ]);
    });
  });

  test('resuming on the same day does not reload; on a new day it does',
      () async {
    final repository = _CountingSubscriptions([
      _sub(DateTime.now().add(const Duration(days: 10)), 'Monthly'),
    ]);
    final container = ProviderContainer(
      overrides: [
        subscriptionsRepositoryRepoProvider.overrideWith((ref) => repository),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(subscriptionsNotifierProvider.notifier);
    await notifier.loadData();
    final loadsAfterStart = repository.loads;

    await notifier.refreshIfStale();
    expect(repository.loads, loadsAfterStart);

    await notifier.refreshIfStale(
      now: DateTime.now().add(const Duration(days: 1)),
    );
    expect(repository.loads, greaterThan(loadsAfterStart));
  });
}
