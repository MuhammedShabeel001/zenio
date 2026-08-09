import 'package:freezed_annotation/freezed_annotation.dart';

part 'vault_card_model.freezed.dart';
part 'vault_card_model.g.dart';

@freezed
abstract class VaultCardModel with _$VaultCardModel {
  const factory VaultCardModel({
    required String id,
    required String cardType,
    required String cardNumber,
    required String expiry,
    required String cvv,
  }) = _VaultCardModel;

  factory VaultCardModel.fromJson(Map<String, dynamic> json) =>
      _$VaultCardModelFromJson(json);
}
