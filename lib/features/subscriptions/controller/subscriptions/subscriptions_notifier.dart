import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_state.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
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

  Future<void> deleteSubscription(String id) async {
    final target = state.subscriptions.firstWhere(
      (sub) => sub.id == id,
      orElse: () => const SubscriptionModel(
        id: '',
        title: '',
        category: '',
        amount: 0,
        currency: 'INR',
        dueInText: '',
        iconName: '',
      ),
    );
    if (target.id.isEmpty) return;

    final updated = state.subscriptions.where((sub) => sub.id != id).toList();
    final repo = ref.read(subscriptionsRepositoryRepoProvider);
    await repo.saveSubscriptions(updated);

    final newBalance = state.totalBalance - target.amount;
    state = state.copyWith(
      totalBalance: newBalance < 0 ? 0 : newBalance,
      subscriptions: updated,
    );
  }
}
