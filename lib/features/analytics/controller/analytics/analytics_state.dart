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
    @Default(2678.01) double totalBalance,
    @Default('INR') String selectedCurrency,
    @Default('Week') String selectedPeriod,
    @Default('This Week') String selectedTimeframe,
    @Default([]) List<CategorySpendModel> categorySpends,
  }) = _AnalyticsState;

  factory AnalyticsState.initial() => const AnalyticsState();
}
