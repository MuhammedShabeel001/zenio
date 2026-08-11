import 'package:zenio/features/debts/domain/models/debt_session_model.dart';

abstract class IDebtSessionRepository {
  Future<List<DebtSessionModel>> getDebtSessions();
  Future<DebtSessionModel?> getDebtSessionById(String id);
  Future<void> saveDebtSession(DebtSessionModel debt);
  Future<void> updateDebtSession(DebtSessionModel debt);
  Future<void> deleteDebtSession(String id);
  Future<void> clearAllDebtSessions();
}
