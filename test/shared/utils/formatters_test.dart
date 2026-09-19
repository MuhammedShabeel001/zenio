import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/shared/utils/extensions.dart';
import 'package:zenio/shared/utils/formatters.dart';

void main() {
  group('AppNumberFormat', () {
    test('formatNumber formats numbers with commas', () {
      expect(AppNumberFormat.formatNumber(0), '0');
      expect(AppNumberFormat.formatNumber(12), '12');
      expect(AppNumberFormat.formatNumber(123), '123');
      expect(AppNumberFormat.formatNumber(1234), '1,234');
      expect(AppNumberFormat.formatNumber(12345), '12,345');
      expect(AppNumberFormat.formatNumber(1234567), '1,234,567');
      expect(AppNumberFormat.formatNumber(-12345), '-12,345');
    });

    test('formatAmount formats amounts with decimals and integers properly', () {
      expect(AppNumberFormat.formatAmount(12345.67), '12,345.67');
      expect(AppNumberFormat.formatAmount(12345), '12,345');
      expect(AppNumberFormat.formatAmount(12345.6), '12,345.60');
      expect(AppNumberFormat.formatAmount(0), '0');
      expect(AppNumberFormat.formatAmount(-12345.67), '-12,345.67');

      // With alwaysShowDecimals: true
      expect(AppNumberFormat.formatAmount(12345, alwaysShowDecimals: true), '12,345.00');
      expect(AppNumberFormat.formatAmount(0, alwaysShowDecimals: true), '0.00');
      expect(AppNumberFormat.formatAmount(12345.67, alwaysShowDecimals: true), '12,345.67');
    });

    test('formatCurrency formats with symbol prefix', () {
      expect(AppNumberFormat.formatCurrency(12345.67, symbol: '₹'), '₹ 12,345.67');
      expect(AppNumberFormat.formatCurrency(12345, symbol: r'$'), r'$ 12,345');
      expect(
        AppNumberFormat.formatCurrency(12345, symbol: r'$', alwaysShowDecimals: true),
        r'$ 12,345.00',
      );
      expect(AppNumberFormat.formatCurrency(12345.67), '12,345.67');
    });

    test('formatWholePart and formatDecimalPart work together cleanly', () {
      expect(AppNumberFormat.formatWholePart(12345.67), '12,345');
      expect(AppNumberFormat.formatDecimalPart(12345.67), '.67');

      expect(AppNumberFormat.formatWholePart(12345), '12,345');
      expect(AppNumberFormat.formatDecimalPart(12345), '.00');

      expect(AppNumberFormat.formatWholePart(0), '0');
      expect(AppNumberFormat.formatDecimalPart(0), '.00');

      // Negative numbers
      expect(AppNumberFormat.formatWholePart(-12345.67), '- 12,345');
      expect(AppNumberFormat.formatDecimalPart(-12345.67), '.67');

      // Negative numbers between 0 and -1
      expect(AppNumberFormat.formatWholePart(-0.50), '- 0');
      expect(AppNumberFormat.formatDecimalPart(-0.50), '.50');
    });

    test('NumFormattingX extensions work as expected', () {
      expect(12345.toFormattedNumber, '12,345');
      expect(12345.67.toFormattedAmount, '12,345.67');
      expect(12345.toFormattedAmount, '12,345');
      expect(12345.toFormattedAmountExact, '12,345.00');
    });
  });
}
