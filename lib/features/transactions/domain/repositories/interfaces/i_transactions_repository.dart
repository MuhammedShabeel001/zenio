import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';

abstract class ITransactionsRepository {
  Future<double> getTransactionsBalance();
  Future<List<TransactionDetailModel>> getTransactions();
  Future<void> saveTransactions(List<TransactionDetailModel> transactions);
}
