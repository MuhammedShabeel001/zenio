import 'package:flutter/foundation.dart';

class AppException implements Exception {
  const AppException(this.message, {this.code, this.details});
  final String message;
  final String? details;
  final dynamic code;
  @override
  String toString() => kDebugMode ? message : message + (details ?? '');
}
