import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time. Tests override it to move the calendar, for example
/// across the end of a month.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
