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
    @Default(0) double cardBalance,
    @Default('INR') String selectedCurrency,
    @Default([]) List<WalletCardModel> cards,

    /// The carousel's current page. The carousel loops, so this is not a
    /// card index: the card on screen is `activeCardIndex % cards.length`.
    @Default(0) int activeCardIndex,
  }) = _WalletState;

  factory WalletState.initial() => const WalletState();
}
