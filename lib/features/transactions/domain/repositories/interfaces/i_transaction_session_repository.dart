import 'package:zenio/features/transactions/domain/models/transaction_session_model.dart';

abstract class ITransactionSessionRepository {
  Future<List<TransactionSessionModel>> getTransactionSessions();
  Future<TransactionSessionModel?> getTransactionSessionById(String id);
  Future<void> saveTransactionSession(TransactionSessionModel transaction);
  Future<void> updateTransactionSession(TransactionSessionModel transaction);
  Future<void> deleteTransactionSession(String id);
  Future<void> clearAllTransactionSessions();
}
