import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';

/// Provides the active currency code (e.g. 'INR', 'DLR').
final currencyCodeProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsNotifierProvider).settings;
  return settings.primaryCurrency;
});

/// Provides the active currency symbol (e.g. '₹', r'$').
final currencySymbolProvider = Provider<String>((ref) {
  final code = ref.watch(currencyCodeProvider);
  return getCurrencySymbol(code);
});

/// Helper to get the symbol corresponding to a currency code.
String getCurrencySymbol(String currencyCode) {
  final upper = currencyCode.toUpperCase();
  if (upper == 'DLR' || upper == 'USD') {
    return r'$';
  }
  return '₹';
}
