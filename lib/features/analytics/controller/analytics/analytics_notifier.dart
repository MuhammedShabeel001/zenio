import 'package:zenio/shared/providers/providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/features/analytics/domain/repositories/implementations/analytics_repository.dart';
import 'package:zenio/features/analytics/domain/repositories/interfaces/i_analytics_repository.dart';

part 'analytics_notifier.freezed.dart';
part 'analytics_notifier.g.dart';
part 'analytics_state.dart';

@Riverpod()
class AnalyticsNotifier extends _$AnalyticsNotifier {
  IAnalyticsRepository? _analyticsRepository;

  @override
  AnalyticsState build() {
    try {
      _analyticsRepository = ref.watch(analyticsRepositoryRepoProvider);
      Future.microtask(loadAnalyticsData);
    } catch (_) {
      // SqlitePrefs async handling
    }

    return AnalyticsState.initial();
  }

  Future<void> loadAnalyticsData() async {
    if (_analyticsRepository == null) return;
    state = state.copyWith(status: AnalyticsStatus.loading);
    try {
      final balance = await _analyticsRepository!.getAnalyticsBalance();
      final spends = await _analyticsRepository!.getCategorySpends();
      state = state.copyWith(
        status: AnalyticsStatus.success,
        totalBalance: balance,
        categorySpends: spends,
      );
    } catch (e) {
      state = state.copyWith(status: AnalyticsStatus.error);
    }
  }

  void updatePeriod(String period) {
    state = state.copyWith(selectedPeriod: period);
  }

  void updateTimeframe(String timeframe) {
    state = state.copyWith(selectedTimeframe: timeframe);
  }
}
