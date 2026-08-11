import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_session_model.dart';

part 'subscription_session_state.freezed.dart';

@freezed
abstract class SubscriptionSessionState with _$SubscriptionSessionState {
  const factory SubscriptionSessionState({
    @Default([]) List<SubscriptionSessionModel> subscriptions,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _SubscriptionSessionState;

  factory SubscriptionSessionState.initial() =>
      const SubscriptionSessionState(
        isLoading: true,
      );
}
