import 'dart:math' as math;

import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// [day] of the given month, or its last day when the month is shorter.
DateTime _clampedDay(int year, int month, int day) {
  // Normalise months past December into the following years.
  final normalised = DateTime(year, month);
  return DateTime(
    normalised.year,
    normalised.month,
    math.min(day, _daysInMonth(normalised.year, normalised.month)),
  );
}

/// The billing date after [date] for a [cycle] of 'Daily', 'Weekly',
/// 'Monthly' or 'Yearly'. Monthly and yearly cycles renew on [anchorDay],
/// or on the last day of months that are shorter. Returns null for an
/// unknown cycle.
DateTime? nextBillingDate(DateTime date, String cycle,
    {required int anchorDay,}) {
  switch (cycle.trim().toLowerCase()) {
    case 'daily':
      return DateTime(date.year, date.month, date.day + 1);
    case 'weekly':
      return DateTime(date.year, date.month, date.day + 7);
    case 'monthly':
      return _clampedDay(date.year, date.month + 1, anchorDay);
    case 'yearly':
      return _clampedDay(date.year + 1, date.month, anchorDay);
  }
  return null;
}

/// The subscription with its billing date moved forward past any cycles that
/// have already been billed, so it is due today or later. Returns it
/// unchanged when it is not overdue (or its cycle is unknown).
SubscriptionModel rolledForward(SubscriptionModel subscription, DateTime now) {
  final today = _dateOnly(now);
  final anchorDay =
      (subscription.billingDay ?? subscription.nextBillingDate.day).clamp(1, 31);
  var due = _dateOnly(subscription.nextBillingDate);
  if (!due.isBefore(today)) return subscription;

  while (due.isBefore(today)) {
    final next =
        nextBillingDate(due, subscription.billingCycle, anchorDay: anchorDay);
    // Unknown cycle, or a date that would not move forward: leave it alone
    // rather than loop.
    if (next == null || !next.isAfter(due)) return subscription;
    due = next;
  }
  return subscription.copyWith(nextBillingDate: due, billingDay: anchorDay);
}

/// What [subscription] costs per month on average: weekly × 52 / 12, yearly
/// / 12, daily × 365 / 12. An unknown cycle counts as monthly.
double monthlyEquivalent(SubscriptionModel subscription) {
  final amount = subscription.amount;
  return switch (subscription.billingCycle.trim().toLowerCase()) {
    'daily' => amount * 365 / 12,
    'weekly' => amount * 52 / 12,
    'yearly' => amount / 12,
    _ => amount,
  };
}

/// The total shown for [subscriptions] under [filter]: the monthly
/// equivalent when all cycles are shown (adding a weekly and a yearly price
/// together would mean nothing), otherwise the plain total of that cycle.
double subscriptionsTotal(
  List<SubscriptionModel> subscriptions,
  String filter,
) {
  final allCycles = filter.trim().toLowerCase() == 'all';
  return subscriptions.fold<double>(
    0,
    (sum, sub) => sum + (allCycles ? monthlyEquivalent(sub) : sub.amount),
  );
}
