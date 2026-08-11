import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/subscriptions/controller/subscription_session/subscription_session_state.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_session_model.dart';
import 'package:zenio/features/subscriptions/domain/repositories/implementations/subscription_session_repository.dart';

part 'subscription_session_notifier.g.dart';

@Riverpod(keepAlive: true)
class SubscriptionSessionNotifier extends _$SubscriptionSessionNotifier {
  @override
  SubscriptionSessionState build() {
    _loadSubscriptions();
    return SubscriptionSessionState.initial();
  }

  Future<void> _loadSubscriptions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(subscriptionSessionRepositoryRepoProvider);
      final list = await repo.getSubscriptionSessions();
      state = state.copyWith(
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

  Future<void> addSubscriptionSession(
    SubscriptionSessionModel subscription,
  ) async {
    try {
      final repo = ref.read(subscriptionSessionRepositoryRepoProvider);
      await repo.saveSubscriptionSession(subscription);
      await _loadSubscriptions();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateSubscriptionSession(
    SubscriptionSessionModel subscription,
  ) async {
    try {
      final repo = ref.read(subscriptionSessionRepositoryRepoProvider);
      await repo.updateSubscriptionSession(subscription);
      await _loadSubscriptions();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteSubscriptionSession(String id) async {
    try {
      final repo = ref.read(subscriptionSessionRepositoryRepoProvider);
      await repo.deleteSubscriptionSession(id);
      await _loadSubscriptions();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> clearAllSubscriptions() async {
    try {
      final repo = ref.read(subscriptionSessionRepositoryRepoProvider);
      await repo.clearAllSubscriptionSessions();
      await _loadSubscriptions();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}
