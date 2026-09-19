import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Centralized utility for formatting numbers, currencies, and balance displays.
class AppNumberFormat {
  static final NumberFormat _integerFormatter = NumberFormat('#,##0');
  static final NumberFormat _decimalFormatter = NumberFormat('#,##0.00');

  /// Formats an integer or whole number count with thousands separators (e.g. 12345 -> '12,345').
  static String formatNumber(num number) {
    return _integerFormatter.format(number);
  }

  /// Formats money / currency amounts with thousands separators.
  /// When [alwaysShowDecimals] is false, integer amounts have no decimals (e.g. 12,345) and fractional amounts have two decimals (e.g. 12,345.67).
  /// When [alwaysShowDecimals] is true, amounts always have two decimal places (e.g. 12,345.00).
  static String formatAmount(double amount, {bool alwaysShowDecimals = false}) {
    if (!alwaysShowDecimals && amount == amount.toInt()) {
      return _integerFormatter.format(amount.toInt());
    }
    return _decimalFormatter.format(amount);
  }

  /// Formats currency with optional symbol prefix (e.g. '₹ 12,345.67' or '$ 12,345').
  static String formatCurrency(
    double amount, {
    String symbol = '',
    bool alwaysShowDecimals = false,
  }) {
    final formatted = formatAmount(amount, alwaysShowDecimals: alwaysShowDecimals);
    return symbol.isEmpty ? formatted : '$symbol $formatted';
  }

  /// Formats the whole number part for split-styled balance headers (e.g. '12,345' or '- 12,345').
  static String formatWholePart(double amount) {
    final isNegative = amount < 0;
    final absWhole = amount.abs().toInt();
    final formattedStr = _integerFormatter.format(absWhole);
    return isNegative ? '- $formattedStr' : formattedStr;
  }

  /// Formats the two-digit decimal part for split-styled balance headers (e.g. '.67' or '.00').
  static String formatDecimalPart(double amount) {
    final absAmount = amount.abs();
    final decimal = ((absAmount - absAmount.toInt()) * 100).round();
    return '.${decimal.toString().padLeft(2, '0')}';
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  CurrencyInputFormatter({
    this.decimalRange = 2,
    this.allowNegative = true,
  });

  final int decimalRange;
  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If whole string is selected and deleted, return 0.00
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    if (oldValue.text == '0') {
      return TextEditingValue(
        text: newValue.text.replaceFirst('0', ''),
        selection: const TextSelection.collapsed(offset: 1),
      );
    }

    if (double.tryParse(newValue.text) == null) {
      return const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // restrict to 2 decimal places
    if (newValue.text.contains('.')) {
      final decimalIndex = newValue.text.indexOf('.');
      if (decimalIndex + decimalRange + 1 < newValue.text.length) {
        return TextEditingValue(
          text: newValue.text.substring(0, decimalIndex + decimalRange + 1),
          selection:
              TextSelection.collapsed(offset: decimalIndex + decimalRange + 1),
        );
      }
    }

    return newValue;

    // // if new value is whole number return it with 2 decimal places
    // if (newValue.text.length == 1) {
    //   return TextEditingValue(
    //     text: '${newValue.text}.00',
    //     selection: newValue.selection,
    //   );
    // }
    // if (oldValue.text.contains('.') && !newValue.text.contains('.')) {
    //   // Find the position of decimal in old value
    //   final decimalPosition = oldValue.text.indexOf('.');

    //   // Return old value with cursor positioned before decimal
    //   return TextEditingValue(
    //     text: oldValue.text,
    //     selection: TextSelection.collapsed(offset: decimalPosition),
    //   );
    // }

    // final selectionIndex = newValue.selection.end;
    // final newText = newValue.text;
    // final oldText = oldValue.text;
    // late final String value;
    // // if old value is 0.00 then if new digit is entered replace the old value with the new digit like 1.00
    // if (double.tryParse(oldText) == 0) {
    //   value = newText.replaceFirst(RegExp('0'), '');
    // } else {
    //   value = newText;
    // }

    // final newString = double.tryParse(value)?.toStringAsFixed(decimalRange)
    // ?? '0.00';

    // return TextEditingValue(
    //   text: newString,
    //   selection: TextSelection.collapsed(offset: selectionIndex),
    // );
  }
}
