/// The currency code to show for a stored one. US dollars have always been
/// stored as "DLR"; they are shown as the standard "USD". Stored values are
/// left as they are.
String currencyDisplayCode(String storedCode) {
  final upper = storedCode.trim().toUpperCase();
  return upper == 'DLR' ? 'USD' : upper;
}
