part of 'wallet_notifier.dart';

enum WalletStatus {
  initial,
  loading,
  success,
  error,
}

@freezed
sealed class WalletState with _$WalletState {
  const factory WalletState({
    @Default(WalletStatus.initial) WalletStatus status,
    @Default(2678.01) double cardBalance,
    @Default('INR') String selectedCurrency,
    @Default([]) List<WalletCardModel> cards,
    @Default(0) int activeCardIndex,
  }) = _WalletState;

  factory WalletState.initial() => const WalletState();
}
