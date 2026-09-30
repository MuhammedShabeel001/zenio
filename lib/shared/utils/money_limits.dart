/// The largest amount Zenio accepts for a single value: a transaction, an
/// opening balance, a debt, a subscription or a bill. It keeps exact cents
/// (it is far below 2^53 cents) and is far above any personal amount.
const double maxMoneyAmount = 999999999999.99;

/// Digits before the decimal point that amount fields accept.
const int maxMoneyIntegerDigits = 12;

/// Whether [value] may be stored as an amount: a finite number no larger
/// than [maxMoneyAmount] either way. NaN and infinities never are.
bool isStorableAmount(num value) =>
    value.isFinite && value.abs() <= maxMoneyAmount;

/// Whether [value] may be stored as a wallet balance. A balance adds up many
/// amounts, so it is only required to be a finite number.
bool isStorableBalance(num value) => value.isFinite;

/// A financial value that must not be stored: NaN, an infinity, or an
/// amount beyond [maxMoneyAmount].
class InvalidAmountException implements Exception {
  const InvalidAmountException(this.field);

  /// What the value was for, e.g. "transaction amount".
  final String field;

  @override
  String toString() => 'Invalid $field: not a storable amount.';
}

/// Throws [InvalidAmountException] unless [value] is a storable amount.
/// For values about to be stored.
void checkStorableAmount(num value, String field) {
  if (!isStorableAmount(value)) throw InvalidAmountException(field);
}

/// Throws [InvalidAmountException] if a stored [value] cannot be used: NaN
/// or an infinity, which would break every total and list it reached. A
/// finite value is read even beyond [maxMoneyAmount], which only limits new
/// values, so nothing older versions stored disappears.
void checkReadableAmount(num value, String field) {
  if (!value.isFinite) throw InvalidAmountException(field);
}
