import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/domain/repositories/implementations/subscriptions_repository.dart';

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

  factory SubscriptionsState.initial() {
    return const SubscriptionsState(
      totalBalance: 0,
      subscriptions: defaultSubscriptionsList,
      selectedFilter: 'All',
      isLoading: false,
    );
  }
}
