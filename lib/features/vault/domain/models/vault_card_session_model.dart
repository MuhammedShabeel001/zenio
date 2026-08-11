import 'package:freezed_annotation/freezed_annotation.dart';

part 'vault_card_session_model.freezed.dart';
part 'vault_card_session_model.g.dart';

@freezed
abstract class VaultCardSessionModel with _$VaultCardSessionModel {
  const factory VaultCardSessionModel({
    required String id,
    required String cardNumber,
    required String cardName,
    required String expiry,
    required String cvv,
  }) = _VaultCardSessionModel;

  factory VaultCardSessionModel.fromJson(Map<String, dynamic> json) =>
      _$VaultCardSessionModelFromJson(json);
}
