import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';

abstract class IMoneyTrackerRepository {
  /// Returns every readable transaction. Rows that cannot be decoded are
  /// skipped and left untouched in storage.
  Future<List<TransactionModel>> getTransactions();

  /// Inserts a new transaction without touching any other row.
  Future<void> insertTransaction(TransactionModel transaction);

  /// Replaces the stored row that has the same id.
  Future<void> updateTransaction(TransactionModel transaction);

  /// Deletes the row with [id]. Deleting a missing row is a no-op.
  Future<void> deleteTransaction(String id);

  /// Points every transaction of wallet [oldName] (including transfers) at
  /// [newName], in one database transaction.
  Future<void> renameWallet(String oldName, String newName);
}
