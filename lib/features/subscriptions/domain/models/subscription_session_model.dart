import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_session_model.freezed.dart';
part 'subscription_session_model.g.dart';

@freezed
abstract class SubscriptionSessionModel with _$SubscriptionSessionModel {
  const factory SubscriptionSessionModel({
    required String id,
    required String subscriptionName,
    required String category,
    required double amount,
    required String billingCycle,
    required String startDate,
  }) = _SubscriptionSessionModel;

  factory SubscriptionSessionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionSessionModelFromJson(json);
}
