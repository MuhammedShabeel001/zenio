import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';

/// What kind of wallet this is, from its type ("CREDIT CARD", "CASH", or a
/// type the user typed in).
extension WalletKind on WalletCardModel {
  /// A credit card: spending on it is borrowing, so its balance may go
  /// below zero.
  bool get isCredit => cardType.toUpperCase().contains('CREDIT');

  /// A debit or credit card. Other wallets (bank, cash, savings) have no
  /// card number to show.
  bool get isCard => cardType.toUpperCase().contains('CARD');

  /// The last four digits of a card's number, or null when there is none to
  /// show. Only these are ever shown.
  String? get lastFour {
    if (!isCard) return null;
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 4 ? digits.substring(digits.length - 4) : null;
  }
}
