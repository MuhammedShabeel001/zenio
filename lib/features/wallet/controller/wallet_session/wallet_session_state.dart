import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/wallet/domain/models/wallet_session_model.dart';

part 'wallet_session_state.freezed.dart';

@freezed
abstract class WalletSessionState with _$WalletSessionState {
  const factory WalletSessionState({
    @Default([]) List<WalletSessionModel> wallets,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _WalletSessionState;

  factory WalletSessionState.initial() => const WalletSessionState(
        isLoading: true,
      );
}
