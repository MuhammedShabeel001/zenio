import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

@freezed
abstract class SubscriptionModel with _$SubscriptionModel {
  const factory SubscriptionModel({
    required String id,
    required String title,
    required String category,
    required double amount,
    required String currency,
    required DateTime nextBillingDate,
    required String billingCycle,
    required String iconName,

    /// The day of the month it renews on. Kept so that a subscription on the
    /// 31st returns to the 31st after a shorter month. Null for subscriptions
    /// saved before this was stored; [nextBillingDate]'s day is used then.
    int? billingDay,
  }) = _SubscriptionModel;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);
}
