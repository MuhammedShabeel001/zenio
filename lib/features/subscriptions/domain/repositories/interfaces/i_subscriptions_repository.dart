import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';

abstract class ISubscriptionsRepository {
  Future<double> getSubscriptionsBalance();
  Future<List<SubscriptionModel>> getSubscriptions();
  Future<void> saveSubscriptions(List<SubscriptionModel> subscriptions);
}
