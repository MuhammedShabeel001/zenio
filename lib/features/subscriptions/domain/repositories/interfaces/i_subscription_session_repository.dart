import 'package:zenio/features/subscriptions/domain/models/subscription_session_model.dart';

abstract class ISubscriptionSessionRepository {
  Future<List<SubscriptionSessionModel>> getSubscriptionSessions();
  Future<SubscriptionSessionModel?> getSubscriptionSessionById(String id);
  Future<void> saveSubscriptionSession(SubscriptionSessionModel subscription);
  Future<void> updateSubscriptionSession(SubscriptionSessionModel subscription);
  Future<void> deleteSubscriptionSession(String id);
  Future<void> clearAllSubscriptionSessions();
}
