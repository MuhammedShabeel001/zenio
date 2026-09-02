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
    @JsonKey(name: 'balance') @Default(0.0) double balance,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'is_frozen') @Default(false) bool isFrozen,
  }) = _WalletCardModel;

  factory WalletCardModel.fromJson(Map<String, dynamic> json) =>
      _$WalletCardModelFromJson(json);
}
