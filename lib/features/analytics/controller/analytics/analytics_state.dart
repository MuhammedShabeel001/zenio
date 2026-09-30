part of 'analytics_notifier.dart';

enum AnalyticsStatus {
  initial,
  loading,
  success,
  error,
}

@freezed
sealed class AnalyticsState with _$AnalyticsState {
  const factory AnalyticsState({
    @Default(AnalyticsStatus.initial) AnalyticsStatus status,
    @Default(0.0) double totalBalance,
    @Default('INR') String selectedCurrency,
    @Default('All Wallets') String selectedWallet,
    @Default('Monthly') String selectedPeriod,
    @Default('September') String selectedTimeframe,
    @Default([]) List<CategorySpendModel> categorySpends,
  }) = _AnalyticsState;

  factory AnalyticsState.initial() => const AnalyticsState();
}

extension AnalyticsStateCaption on AnalyticsState {
  /// What the spending headline covers: "Spent · September", with the
  /// wallet when one is chosen ("Spent · This week · HDFC").
  String get spentCaption {
    final allWallets =
        selectedWallet == 'All Wallets' || selectedWallet == 'All';
    return [
      'Spent',
      periodLabel(selectedPeriod, selectedTimeframe),
      if (!allWallets) selectedWallet,
    ].join(' · ');
  }
}
