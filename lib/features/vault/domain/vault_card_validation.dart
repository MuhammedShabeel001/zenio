/// Checks the fields of a vault card. Returns a message for the first
/// problem, or null when the card can be saved.
///
/// When editing, pass the saved values as [original]: fields left unchanged
/// are not checked, so cards saved before these rules can still be edited.
String? validateVaultCard({
  required String type,
  required String number,
  required String expiry,
  required String cvv,
  ({String number, String expiry, String cvv})? original,
}) {
  if (type.trim().isEmpty) return 'Enter a card type, for example Visa';

  final digits = number.replaceAll(RegExp(r'[\s-]'), '');
  if (number != original?.number && !RegExp(r'^\d{12,19}$').hasMatch(digits)) {
    return 'Enter a card number of 12 to 19 digits';
  }

  final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(expiry.trim());
  final month = match == null ? null : int.parse(match.group(1)!);
  if (expiry != original?.expiry &&
      (month == null || month < 1 || month > 12)) {
    return 'Enter the expiry date as MM/YY';
  }

  if (cvv != original?.cvv && !RegExp(r'^\d{3,4}$').hasMatch(cvv.trim())) {
    return 'Enter the 3 or 4 digit CVV';
  }
  return null;
}
