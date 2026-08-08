import 'dart:async';

import 'package:flutter/services.dart';

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase().trim(),
      selection: newValue.selection,
    );
  }
}

class Debouncer {
  Debouncer({
    required this.milliseconds,
  });
  final int milliseconds;
  // VoidCallback action;
  Timer? _timer;

  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

bool isValidFileSize(Uint8List bytes, double sizeInMB) {
  final sizeInMB = bytes.length / (1024 * 1024);
  return sizeInMB <= sizeInMB;
}
