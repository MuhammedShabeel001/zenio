import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_state.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/domain/repositories/implementations/subscriptions_repository.dart';

part 'subscriptions_notifier.g.dart';

@Riverpod(keepAlive: true)
class SubscriptionsNotifier extends _$SubscriptionsNotifier {
  @override
  SubscriptionsState build() {
    try {
      ref.watch(subscriptionsRepositoryRepoProvider);
      Future.microtask(_loadData);
    } catch (_) {}
    return SubscriptionsState.initial();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(subscriptionsRepositoryRepoProvider);
      final list = await repo.getSubscriptions();
      
      final filteredList = _filterSubscriptions(list, state.selectedFilter);
      final balance = _calculateTotalBalance(filteredList);

      state = state.copyWith(
        totalBalance: balance,
        subscriptions: filteredList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadData() async => _loadData();

  List<SubscriptionModel> _filterSubscriptions(
    List<SubscriptionModel> allSubscriptions,
    String filter,
  ) {
    if (filter.toLowerCase() == 'all') {
      return allSubscriptions;
    }
    return allSubscriptions.where((sub) {
      return sub.billingCycle.toLowerCase() == filter.toLowerCase();
    }).toList();
  }

  double _calculateTotalBalance(List<SubscriptionModel> subs) {
    double total = 0;
    for (final sub in subs) {
      total += sub.amount;
    }
    return total;
  }

  void updateFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
    unawaited(_loadData());
  }

  Future<void> deleteSubscription(String id) async {
    final repo = ref.read(subscriptionsRepositoryRepoProvider);
    final allList = await repo.getSubscriptions();
    final updated = allList.where((sub) => sub.id != id).toList();
    
    await repo.saveSubscriptions(updated);
    unawaited(_loadData());
  }

  Future<void> addSubscription(SubscriptionModel sub) async {
    final repo = ref.read(subscriptionsRepositoryRepoProvider);
    final allList = await repo.getSubscriptions();
    final updated = [...allList, sub];
    
    await repo.saveSubscriptions(updated);
    unawaited(_loadData());
  }

  Future<void> updateSubscription(SubscriptionModel sub) async {
    final repo = ref.read(subscriptionsRepositoryRepoProvider);
    final allList = await repo.getSubscriptions();
    final updated = allList.map((s) => s.id == sub.id ? sub : s).toList();

    await repo.saveSubscriptions(updated);
    unawaited(_loadData());
  }
}
