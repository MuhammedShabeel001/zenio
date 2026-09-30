import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';

/// The type stored for a wallet made with the Credit preset.
const String creditCardWalletType = 'CREDIT CARD';

/// Whether [type] is the Credit preset, matched the way the wallet forms
/// match presets: ignoring case, with "CREDIT" as a short form. A type the
/// user named is not a credit card even with "credit" in it, such as
/// "Credit union savings".
bool isCreditWalletType(String type) {
  final upper = type.trim().toUpperCase();
  return upper == creditCardWalletType || upper == 'CREDIT';
}

/// Whether [number] was made up by Zenio when the wallet was added, rather
/// than entered by the user: four random groups of 1000–9999 joined by two
/// spaces (Sept 2026 and before), or briefly "**** **** **** " and one such
/// group. The number field takes digits only, so users did not type these.
bool isGeneratedWalletNumber(String number) =>
    _generatedWalletNumber.hasMatch(number);

final RegExp _generatedWalletNumber = RegExp(
  r'^(?:[1-9]\d{3}  [1-9]\d{3}  [1-9]\d{3}  [1-9]\d{3}'
  r'|\*{4} \*{4} \*{4} [1-9]\d{3})$',
);

/// What kind of wallet this is, from its type ("CREDIT CARD", "CASH", or a
/// type the user typed in).
extension WalletKind on WalletCardModel {
  /// A credit card: spending on it is borrowing, so its balance may go
  /// below zero.
  bool get isCredit => isCreditWalletType(cardType);

  /// A debit or credit card. Other wallets (bank, cash, savings) have no
  /// card number to show.
  bool get isCard => cardType.toUpperCase().contains('CARD');

  /// The type as it reads in a sentence or list: "Debit card", "Cash", or
  /// the user's own name for it.
  String get typeLabel {
    final type = cardType.trim();
    return switch (type.toUpperCase()) {
      'BANK' => 'Bank',
      'DEBIT CARD' || 'DEBIT' => 'Debit card',
      'CREDIT CARD' || 'CREDIT' => 'Credit card',
      'CASH' => 'Cash',
      'SAVINGS' => 'Savings',
      _ => type,
    };
  }

  /// The last four digits of a card's number, or null when there is none to
  /// show. Only these are ever shown, and never those of a number Zenio made
  /// up (it stays stored, but is treated as no number).
  String? get lastFour {
    if (!isCard || isGeneratedWalletNumber(cardNumber)) return null;
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 4 ? digits.substring(digits.length - 4) : null;
  }
}
