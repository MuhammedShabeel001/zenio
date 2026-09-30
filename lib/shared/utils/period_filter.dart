import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:zenio/shared/utils/datetime.dart';

/// A range of whole days, from [start] (inclusive) to [end] (exclusive).
@immutable
class DayRange {
  const DayRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is DayRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DayRange($start, $end)';
}

/// Timeframe shown for a custom period before a range is picked.
const String allTimeTimeframe = 'All time';

/// How a picked custom range is written into the timeframe (and shown).
final DateFormat customRangeDateFormat = DateFormat('dd MMM yy');

/// The timeframe text for a custom range from [start] to [end] (inclusive).
String customRangeTimeframe(DateTime start, DateTime end) =>
    '${customRangeDateFormat.format(start)} - '
    '${customRangeDateFormat.format(end)}';

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

/// The days selected by a period ('Daily', 'Weekly', 'Monthly', 'Custom')
/// and timeframe (for example 'Yesterday', 'Last week', 'December' or
/// '20 Dec 25 - 05 Jan 26'), or null when everything is selected.
///
/// A month means its most recent occurrence, so in January 'December' is the
/// December just gone rather than one in the future.
DayRange? resolvePeriodRange(
  String period,
  String timeframe, {
  DateTime? now,
}) {
  final today = _day(now ?? DateTime.now());
  final frame = timeframe.trim().toLowerCase();

  switch (period.trim().toLowerCase()) {
    case 'daily':
      final day = switch (frame) {
        'today' => today,
        'yesterday' => today.subtract(const Duration(days: 1)),
        _ => null,
      };
      return day == null
          ? null
          : DayRange(day, DateTime(day.year, day.month, day.day + 1));

    case 'weekly':
      final thisMonday = DateTime(
        today.year,
        today.month,
        today.day - (today.weekday - DateTime.monday),
      );
      final monday = switch (frame) {
        'this week' => thisMonday,
        'last week' => DateTime(
            thisMonday.year,
            thisMonday.month,
            thisMonday.day - 7,
          ),
        _ => null,
      };
      return monday == null
          ? null
          : DayRange(
              monday,
              DateTime(monday.year, monday.month, monday.day + 7),
            );

    case 'monthly':
      final index = _monthNames.indexWhere((m) => m.toLowerCase() == frame);
      if (index == -1) return null;
      final month = index + 1;
      final year = month > today.month ? today.year - 1 : today.year;
      return DayRange(DateTime(year, month), DateTime(year, month + 1));

    case 'custom':
      final parts = timeframe.split(' - ');
      if (parts.length != 2) return null;
      final start = _parseRangeDay(parts[0], today);
      final end = _parseRangeDay(parts[1], today);
      if (start == null || end == null) return null;
      final first = start.isAfter(end) ? end : start;
      final last = start.isAfter(end) ? start : end;
      return DayRange(first, DateTime(last.year, last.month, last.day + 1));
  }
  return null;
}

/// Reads 'dd MMM yy', or the older 'dd MMM' (taken as the current year).
DateTime? _parseRangeDay(String text, DateTime today) {
  final value = text.trim();
  try {
    return _day(customRangeDateFormat.parseStrict(value));
  } catch (_) {}
  try {
    final parsed = DateFormat('dd MMM').parseStrict(value);
    return DateTime(today.year, parsed.month, parsed.day);
  } catch (_) {
    return null;
  }
}

/// The items of [items] dated within the selected period. Items whose date
/// cannot be read are left out of any bounded period.
List<T> filterByPeriod<T>(
  List<T> items,
  String Function(T item) dateOf,
  String period,
  String timeframe, {
  DateTime? now,
}) {
  final range = resolvePeriodRange(period, timeframe, now: now);
  if (range == null) return items;
  return items.where((item) {
    final date = DateTimeUtils.parseTransactionDate(dateOf(item));
    return date != null && range.contains(date);
  }).toList();
}
