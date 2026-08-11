import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_session_model.freezed.dart';
part 'wallet_session_model.g.dart';

@freezed
abstract class WalletSessionModel with _$WalletSessionModel {
  const factory WalletSessionModel({
    required String walletId,
    required String walletName,
    required String walletType,
    required String date,
    required bool isFreezed,
    required double amount,
    required String cardColorCode,
  }) = _WalletSessionModel;

  factory WalletSessionModel.fromJson(Map<String, dynamic> json) =>
      _$WalletSessionModelFromJson(json);
}
