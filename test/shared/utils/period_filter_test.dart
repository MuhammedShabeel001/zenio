import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/shared/utils/period_filter.dart';

void main() {
  // A Wednesday.
  final now = DateTime(2026, 9, 30, 15, 45);

  DayRange? range(String period, String timeframe) =>
      resolvePeriodRange(period, timeframe, now: now);

  group('resolvePeriodRange', () {
    test('daily covers exactly one day', () {
      expect(
        range('Daily', 'Today'),
        DayRange(DateTime(2026, 9, 30), DateTime(2026, 10)),
      );
      expect(
        range('Daily', 'Yesterday'),
        DayRange(DateTime(2026, 9, 29), DateTime(2026, 9, 30)),
      );
    });

    test('this week runs Monday to Sunday, including later days', () {
      final week = range('Weekly', 'This week')!;
      expect(week, DayRange(DateTime(2026, 9, 28), DateTime(2026, 10, 5)));
      expect(week.contains(DateTime(2026, 10, 4)), isTrue);
      expect(week.contains(DateTime(2026, 10, 5)), isFalse);
    });

    test('last week does not include this Monday', () {
      final week = range('Weekly', 'Last week')!;
      expect(week.contains(DateTime(2026, 9, 21)), isTrue);
      expect(week.contains(DateTime(2026, 9, 27)), isTrue);
      expect(week.contains(DateTime(2026, 9, 28)), isFalse);
    });

    test('a month means its most recent occurrence', () {
      expect(
        range('Monthly', 'September'),
        DayRange(DateTime(2026, 9), DateTime(2026, 10)),
      );
      expect(
        range('Monthly', 'December'),
        DayRange(DateTime(2025, 12), DateTime(2026)),
      );
    });

    test('a custom range keeps its years and includes its last day', () {
      final custom = range('Custom', '20 Dec 25 - 05 Jan 26')!;
      expect(custom.contains(DateTime(2025, 12, 31)), isTrue);
      expect(custom.contains(DateTime(2026, 1, 5)), isTrue);
      expect(custom.contains(DateTime(2026, 1, 6)), isFalse);
      expect(custom.contains(DateTime(2026, 12, 25)), isFalse);
    });

    test('a custom range picked backwards still works', () {
      expect(
        range('Custom', '05 Jan 26 - 20 Dec 25'),
        range('Custom', '20 Dec 25 - 05 Jan 26'),
      );
    });

    test('a custom range without years is read as this year', () {
      expect(
        range('Custom', '01 Sep - 02 Sep'),
        DayRange(DateTime(2026, 9), DateTime(2026, 9, 3)),
      );
    });

    test('an unpicked custom range selects everything', () {
      expect(range('Custom', allTimeTimeframe), isNull);
    });

    test('the timeframe written for a picked range reads back the same', () {
      final text =
          customRangeTimeframe(DateTime(2025, 12, 20), DateTime(2026, 1, 5));
      expect(text, '20 Dec 25 - 05 Jan 26');
      expect(
        range('Custom', text),
        DayRange(DateTime(2025, 12, 20), DateTime(2026, 1, 6)),
      );
    });
  });

  test('filterByPeriod leaves out items whose date cannot be read', () {
    final items = ['30-09-2026', 'not a date', '15-08-2026'];

    final result =
        filterByPeriod(items, (d) => d, 'Monthly', 'September', now: now);

    expect(result, ['30-09-2026']);
  });
}
