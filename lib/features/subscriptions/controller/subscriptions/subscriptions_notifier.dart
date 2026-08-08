import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_state.dart';
import 'package:zenio/features/subscriptions/domain/repositories/implementations/subscriptions_repository.dart';

part 'subscriptions_notifier.g.dart';

@Riverpod(keepAlive: true)
class SubscriptionsNotifier extends _$SubscriptionsNotifier {
  @override
  SubscriptionsState build() {
    _loadData();
    return SubscriptionsState.initial();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(subscriptionsRepositoryRepoProvider);
      final balance = await repo.getSubscriptionsBalance();
      final list = await repo.getSubscriptions();
      state = state.copyWith(
        totalBalance: balance,
        subscriptions: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void updateFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }
}
