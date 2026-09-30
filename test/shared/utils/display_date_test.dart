import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/shared/utils/datetime.dart';

void main() {
  final now = DateTime(2026, 9, 30, 12);

  test('dates read one way: Today, Yesterday, Tomorrow or "30 Sep 2026"', () {
    expect(DateTimeUtils.displayDate(DateTime(2026, 9, 30), now: now), 'Today');
    expect(
      DateTimeUtils.displayDate(DateTime(2026, 9, 29, 23), now: now),
      'Yesterday',
    );
    expect(
      DateTimeUtils.displayDate(DateTime(2026, 10), now: now),
      'Tomorrow',
    );
    expect(
      DateTimeUtils.displayDate(DateTime(2026, 9, 3), now: now),
      '3 Sep 2026',
    );
    expect(
      DateTimeUtils.displayDate(DateTime(2027, 1, 15), now: now),
      '15 Jan 2027',
    );
  });

  test('every stored format reads as a date, not as raw text', () {
    for (final (stored, expected) in [
      ('17-09-2026', DateTime(2026, 9, 17)), // transactions
      ('17 September 2026', DateTime(2026, 9, 17)), // debts, notes
      ('17 Sep 2026', DateTime(2026, 9, 17)),
      ('September 17, 2026', DateTime(2026, 9, 17)), // wallets
      ('September 17 , 2026', DateTime(2026, 9, 17)), // older wallets
      ('Thursday, September 17, 2026', DateTime(2026, 9, 17)),
    ]) {
      expect(
        DateTimeUtils.parseTransactionDate(stored),
        expected,
        reason: stored,
      );
    }
    // Text that is not a date is shown as it is.
    expect('Unknown'.toRelativeDate, 'Unknown');
  });

  test('a stored timestamp gives its time of day', () {
    expect(DateTimeUtils.timeOfTimestamp('26-09-30   14 : 05'), '14:05');
    expect(DateTimeUtils.timeOfTimestamp('26-09-30'), isNull);
    expect(DateTimeUtils.timeOfTimestamp(null), isNull);
  });
}
