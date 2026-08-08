import 'package:zenio/features/home/domain/models/summary/financial_summary_model.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';

abstract class IMoneyTrackerRepository {
  Future<FinancialSummaryModel> getSummary();
  Future<List<TransactionModel>> getTransactions();
  Future<void> saveSummary(FinancialSummaryModel summary);
  Future<void> saveTransactions(List<TransactionModel> transactions);
}
