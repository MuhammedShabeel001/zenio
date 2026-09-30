import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_card_model.freezed.dart';
part 'wallet_card_model.g.dart';

@freezed
sealed class WalletCardModel with _$WalletCardModel {
  const factory WalletCardModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'bank_name') required String bankName,
    @JsonKey(name: 'card_number') required String cardNumber,
    @JsonKey(name: 'card_type') required String cardType,
    @JsonKey(name: 'gradient_start') required String gradientStartHex,
    @JsonKey(name: 'gradient_end') required String gradientEndHex,

    /// The current balance: [openingBalance] plus this wallet's transactions.
    /// Stored as a cache so older app versions still show the right amount.
    @JsonKey(name: 'balance') @Default(0.0) double balance,

    /// The balance before any recorded transaction. Null for wallets saved
    /// before balances were derived from transactions (not yet migrated).
    @JsonKey(name: 'opening_balance') double? openingBalance,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'is_frozen') @Default(false) bool isFrozen,
  }) = _WalletCardModel;

  factory WalletCardModel.fromJson(Map<String, dynamic> json) =>
      _$WalletCardModelFromJson(json);
}
