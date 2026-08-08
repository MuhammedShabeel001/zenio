import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';

part 'subscriptions_state.freezed.dart';

@freezed
abstract class SubscriptionsState with _$SubscriptionsState {
  const factory SubscriptionsState({
    required double totalBalance,
    required List<SubscriptionModel> subscriptions,
    required String selectedFilter,
    required bool isLoading,
    String? errorMessage,
  }) = _SubscriptionsState;

  factory SubscriptionsState.initial() => const SubscriptionsState(
        totalBalance: 2678.01,
        subscriptions: [],
        selectedFilter: 'All',
        isLoading: false,
      );
}
