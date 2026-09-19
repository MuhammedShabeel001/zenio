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

  /// Parses an amount string that may contain thousands separators or currency symbols.
  /// (e.g. '12,345.67' or '₹ 12,345' -> 12345.67)
  static double parseAmount(String? text) {
    if (text == null || text.trim().isEmpty) return 0;
    final cleaned = text.replaceAll(',', '').replaceAll(RegExp(r'[^\d.-]'), '').trim();
    return double.tryParse(cleaned) ?? 0;
  }
}

/// Automatically formats numbers entered into text fields with commas (thousands separators)
/// as the user types (e.g. 12345.67 -> 12,345.67), while preserving cursor position.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  ThousandsSeparatorInputFormatter({this.decimalRange = 2});

  final int decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Only allow digits, commas, and at most one decimal point
    final stripped = newValue.text.replaceAll(',', '');
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(stripped)) {
      return oldValue;
    }

    // Handle backspace when deleted character was comma
    var textToFormat = newValue.text;
    var cursorAdjustment = 0;
    if (oldValue.text.length - newValue.text.length == 1 &&
        oldValue.selection.baseOffset > 0 &&
        oldValue.selection.baseOffset <= oldValue.text.length &&
        oldValue.text[oldValue.selection.baseOffset - 1] == ',') {
      final deleteIndex = oldValue.selection.baseOffset - 2;
      if (deleteIndex >= 0) {
        final before = oldValue.text.substring(0, deleteIndex);
        final after = oldValue.text.substring(oldValue.selection.baseOffset);
        textToFormat = '$before$after';
        cursorAdjustment = -1;
      }
    }

    final raw = textToFormat.replaceAll(',', '');
    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (raw == '.') {
      return const TextEditingValue(
        text: '0.',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    final parts = raw.split('.');
    var intPart = parts[0];
    var decPart = parts.length > 1 ? parts.sublist(1).join() : null;

    if (intPart.length > 1 && intPart.startsWith('0')) {
      intPart = intPart.replaceFirst(RegExp('^0+'), '');
      if (intPart.isEmpty) intPart = '0';
    }

    final formattedInt = intPart.isEmpty
        ? '0'
        : intPart.replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (m) => ',',
          );

    final String formattedText;
    if (decPart != null) {
      if (decPart.length > decimalRange) {
        decPart = decPart.substring(0, decimalRange);
      }
      formattedText = '$formattedInt.$decPart';
    } else if (textToFormat.endsWith('.')) {
      formattedText = '$formattedInt.';
    } else {
      formattedText = formattedInt;
    }

    final selOffset = (newValue.selection.baseOffset + cursorAdjustment)
        .clamp(0, textToFormat.length);
    final nonCommaBeforeCursor =
        textToFormat.substring(0, selOffset).replaceAll(',', '').length;

    var newOffset = 0;
    var count = 0;
    for (var i = 0; i < formattedText.length; i++) {
      if (count == nonCommaBeforeCursor) {
        newOffset = i;
        break;
      }
      if (formattedText[i] != ',') {
        count++;
      }
      newOffset = i + 1;
    }

    newOffset = newOffset.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

class CurrencyInputFormatter extends ThousandsSeparatorInputFormatter {
  CurrencyInputFormatter({
    super.decimalRange,
  });
}
