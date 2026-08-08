import 'package:flutter/services.dart';

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
