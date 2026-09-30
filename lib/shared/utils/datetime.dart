import 'package:flutter/material.dart' show DateUtils;
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class DateTimeUtils {
  // 2023 March 9th 04:00 PM
  static final fullDateFormat = DateFormat("yyyy MMMM d'th' hh:mm a");
  // 2023-07-13T10:48:15.735369
  static final apiDateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS");
  // 2024-01-24 09:31:33.422
  static final apiDateFormatWithoutTimeZone =
      DateFormat('yyyy-MM-dd HH:mm:ss.SSSSSS');
  // 2023-07-13T10:48:15
  static final apiDateFormatWithoutMilliSecond =
      DateFormat("yyyy-MM-dd'T'HH:mm:ss");
  static final formatter = NumberFormat('00');
  // 18:00:00
  static final timeFormat = DateFormat('HH:mm:ss');
  // 06:00 PM
  static final timeFormat12 = DateFormat('hh:mm a');
  // 12 October
  static final dateOnly = DateFormat('dd MMMM');
  // 2023 March 9th
  static final dateWithoutTimeFormat = DateFormat("yyyy MMMM d'th'");
  // 12/12/2012 - 12:00 AM
  static final invoiceFormat = DateFormat('dd/MM/yyyy - hh:mm a');
  // Wed, May 27, 2020 • 9:27:53 AM
  static final pdfFullFormat = DateFormat('EEE, MMM dd, yyyy • hh:mm:ss a');

  /// Robust date parser for transactions supporting multiple common formats:
  /// - dd-MM-yyyy (e.g. 17-09-2026), the format Zenio stores
  /// - EEEE, MMMM d, yyyy (e.g. Thursday, September 17, 2026)
  /// - MMMM d, yyyy (e.g. September 17, 2026)
  /// - yyyy-MM-dd (e.g. 2026-09-17)
  /// - dd/MM/yyyy (e.g. 17/09/2026)
  /// - ISO-8601 (DateTime.tryParse)
  ///
  /// Called for every transaction on every filter and sort, so the common
  /// stored format is read without building formatters or throwing, and
  /// results are cached.
  static DateTime? parseTransactionDate(String? dateStr) {
    if (dateStr == null) return null;
    final clean = dateStr.trim();
    if (clean.isEmpty) return null;

    final cached = _parsedDates[clean];
    if (cached != null || _parsedDates.containsKey(clean)) return cached;

    final parsed = _parseTransactionDate(clean);
    if (_parsedDates.length > 5000) _parsedDates.clear();
    _parsedDates[clean] = parsed;
    return parsed;
  }

  /// How dates read in Zenio: "Today", "Yesterday", "Tomorrow", otherwise
  /// "30 Sep 2026". [now] is for tests.
  static String displayDate(DateTime date, {DateTime? now}) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final day = DateUtils.dateOnly(date);
    final days = day.difference(today).inHours / 24;
    return switch (days.round()) {
      0 => 'Today',
      -1 => 'Yesterday',
      1 => 'Tomorrow',
      _ => _displayFormat.format(day),
    };
  }

  static final DateFormat _displayFormat = DateFormat('d MMM yyyy');

  /// The time of day in a stored timestamp ("yy-MM-dd   HH : mm") as
  /// "HH:mm", or null when it has none.
  static String? timeOfTimestamp(String? timestamp) {
    final match =
        RegExp(r'   (\d{1,2}) ?: ?(\d{2})$').firstMatch(timestamp ?? '');
    return match == null ? null : '${match[1]}:${match[2]}';
  }

  static final Map<String, DateTime?> _parsedDates = {};
  static final RegExp _storedDate = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
  static final DateFormat _longDate = DateFormat('EEEE, MMMM d, yyyy');
  // "30 September 2026" (debts, notes) and "30 Sep 2026".
  static final DateFormat _dayMonthYear = DateFormat('d MMMM yyyy');
  static final DateFormat _dayShortMonthYear = DateFormat('d MMM yyyy');
  static final DateFormat _monthDayYear = DateFormat('MMMM d, yyyy');
  static final DateFormat _slashDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _dashDate = DateFormat('dd-MM-yyyy');

  static DateTime? _parseTransactionDate(String clean) {
    // 1. dd-MM-yyyy, the stored format (fast path, no exceptions).
    final match = _storedDate.firstMatch(clean);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final date = DateTime(year, month, day);
      if (date.month == month && date.day == day) return date;
    }

    // 2. ISO-8601 (yyyy-MM-dd)
    final iso = DateTime.tryParse(clean);
    if (iso != null) return iso;

    // 3. The other formats older versions stored.
    // Older wallets stored "September 30 , 2026".
    final tidy = clean.replaceAll(' ,', ',');
    for (final format in [_longDate, _monthDayYear, _slashDate, _dashDate]) {
      try {
        return format.parse(tidy);
      } catch (_) {}
    }
    // Debts and notes store "30 September 2026"; read exactly.
    for (final format in [_dayMonthYear, _dayShortMonthYear]) {
      try {
        return format.parseStrict(tidy);
      } catch (_) {}
    }
    return null;
  }
}

extension DateExtension on String {
  DateTime get fullToDate => DateTimeUtils.fullDateFormat.parse(this);
  DateTime get apiToDate => DateTimeUtils.apiDateFormat.parse(this);
  DateTime get timeToDate => DateTimeUtils.timeFormat.parse(this);
  DateTime get time12ToDate => DateTimeUtils.timeFormat12.parse(this);
  DateTime get dateOnly => DateTimeUtils.dateOnly.parse(this);
  DateTime get apiToDateWithoutMilliSecond =>
      DateTimeUtils.apiDateFormatWithoutMilliSecond.parse(this);
}

extension RelativeDateExtension on String {
  /// A stored date as Zenio shows dates (see [DateTimeUtils.displayDate]),
  /// or the text itself when it is not a date.
  String get toRelativeDate {
    final date = DateTimeUtils.parseTransactionDate(this);
    return date == null ? this : DateTimeUtils.displayDate(date);
  }
}

extension DateTimeExtension on DateTime {
  String get toFullFormat => DateTimeUtils.fullDateFormat.format(this);
  String get toPdfFullFormat => DateTimeUtils.pdfFullFormat.format(this);
  String get toApiDateFormat => DateTimeUtils.apiDateFormat.format(this);
  String get toApiDateFormatWithoutTimeZone =>
      DateTimeUtils.apiDateFormatWithoutTimeZone.format(this);
  String get toTimeFormat => DateTimeUtils.timeFormat.format(this);
  String get toTime12Format => DateTimeUtils.timeFormat12.format(this);
  String get dateOnly => DateTimeUtils.dateOnly.format(this);
  String get toInvoiceFormat => DateTimeUtils.invoiceFormat.format(this);
  String get dateWithoutTimeFormat =>
      DateTimeUtils.dateWithoutTimeFormat.format(this);

  bool isSameDate(DateTime? other) {
    if (other == null) return false;
    return year == other.year && month == other.month && day == other.day;
  }
}

String formatMillisecondsToUTCOffset(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  final hours = duration.inHours;
  final minutes = (duration.inMinutes % 60).abs();

  final sign = (hours >= 0) ? '+' : '-';

  // Ensure two-digit formatting
  final formattedHours = hours.abs().toString().padLeft(2, '0');
  final formattedMinutes = minutes.toString().padLeft(2, '0');

  return '$sign$formattedHours:$formattedMinutes';
}

List<String> getSortedTimeZones() {
  final timeZones = tz.timeZoneDatabase.locations.keys.toList()
    ..sort(
      (a, b) =>
          tz.getLocation(a).currentTimeZone.offset -
          tz.getLocation(b).currentTimeZone.offset,
    );

  return timeZones;
}
