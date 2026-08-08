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
