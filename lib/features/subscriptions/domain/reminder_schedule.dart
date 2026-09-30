import 'package:flutter/foundation.dart';
import 'package:zenio/features/subscriptions/domain/billing_schedule.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';

/// A renewal reminder to schedule.
@immutable
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.renewal,
  });

  /// The notification id: stable between runs, and the same for the same
  /// place in the queue, so scheduling again replaces rather than adds.
  final int id;

  /// When the reminder shows.
  final DateTime at;

  /// The renewal it is about.
  final DateTime renewal;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.id == id &&
      other.at == at &&
      other.renewal == renewal;

  @override
  int get hashCode => Object.hash(id, at, renewal);

  @override
  String toString() => 'PlannedReminder($id, $at, $renewal)';
}

/// How many coming renewals get a reminder. More than one, so reminders keep
/// coming even when Zenio is not opened for a while; more for short cycles.
int remindersAheadFor(String cycle) {
  return switch (cycle.trim().toLowerCase()) {
    'daily' || 'weekly' => 3,
    'monthly' => 2,
    _ => 1,
  };
}

/// A positive 31-bit notification id for the [renewal]th coming renewal of
/// a subscription (0 is the next one). FNV-1a, because `String.hashCode` is
/// not guaranteed to stay the same between app runs; the next renewal keeps
/// the id reminders always had.
int reminderIdFor(String subscriptionId, [int renewal = 0]) {
  final key = renewal == 0 ? subscriptionId : '$subscriptionId#$renewal';
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  // Android notification ids must fit a signed 32-bit int.
  return hash & 0x7FFFFFFF;
}

/// Reminders for the coming renewals of [subscription]: the day before at
/// 9 AM, or 9 AM on the day itself once the day before has passed. A
/// renewal whose reminder time has passed gets none.
List<PlannedReminder> plannedReminders(
  SubscriptionModel subscription,
  DateTime now,
) {
  final anchorDay =
      (subscription.billingDay ?? subscription.nextBillingDate.day)
          .clamp(1, 31);
  final due = subscription.nextBillingDate;
  var renewal = DateTime(due.year, due.month, due.day);
  final reminders = <PlannedReminder>[];
  final count = remindersAheadFor(subscription.billingCycle);

  for (var index = 0; index < count; index++) {
    var at = DateTime(renewal.year, renewal.month, renewal.day - 1, 9);
    if (at.isBefore(now)) {
      at = DateTime(renewal.year, renewal.month, renewal.day, 9);
    }
    if (!at.isBefore(now)) {
      reminders.add(
        PlannedReminder(
          id: reminderIdFor(subscription.id, index),
          at: at,
          renewal: renewal,
        ),
      );
    }
    final next = nextBillingDate(
      renewal,
      subscription.billingCycle,
      anchorDay: anchorDay,
    );
    if (next == null || !next.isAfter(renewal)) break;
    renewal = next;
  }
  return reminders;
}
