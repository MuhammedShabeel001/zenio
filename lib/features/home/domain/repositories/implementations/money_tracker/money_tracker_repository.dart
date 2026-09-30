import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/interfaces/money_tracker/i_money_tracker_repository.dart';
import 'package:zenio/features/wallet/domain/wallet_balances.dart';
import 'package:zenio/shared/providers/providers.dart';

part 'money_tracker_repository.g.dart';

class MoneyTrackerRepository implements IMoneyTrackerRepository {
  MoneyTrackerRepository(this._dbService);

  final LocalDatabaseService _dbService;

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final maps = await _dbService.getTransactionsMap();
    final transactions = <TransactionModel>[];
    for (final map in maps) {
      try {
        transactions.add(TransactionModel.fromJson(_fromRow(map)));
      } catch (error) {
        // Leave the row in the database; it is simply not shown.
        if (kDebugMode) {
          debugPrint('Skipping unreadable transaction ${map['id']}: $error');
        }
      }
    }
    return transactions;
  }

  @override
  Future<void> insertTransaction(TransactionModel transaction) {
    return _dbService.insertTransactionMap(_toRow(transaction));
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final changed = await _dbService.updateTransactionMap(_toRow(transaction));
    if (changed == 0) {
      throw StateError('Transaction ${transaction.id} no longer exists.');
    }
  }

  @override
  Future<void> deleteTransaction(String id) {
    return _dbService.deleteTransactionMap(id);
  }

  @override
  Future<void> renameWallet(String oldName, String newName) async {
    await _dbService.updateTransactionRows((row) {
      final renamed = renamedWalletReferences(
        title: row['title']! as String,
        bankName: row['bank_name'] as String?,
        oldName: oldName,
        newName: newName,
      );
      if (renamed == null) return null;
      return {'title': renamed.title, 'bank_name': renamed.bankName};
    });
  }

  /// SQLite stores booleans as 0/1.
  static Map<String, dynamic> _fromRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    final isIncome = map['is_income'];
    map['is_income'] = isIncome == 1 || isIncome == true;
    return map;
  }

  static Map<String, dynamic> _toRow(TransactionModel transaction) {
    final map = transaction.toJson();
    map['is_income'] = transaction.isIncome ? 1 : 0;
    return map;
  }
}

@Riverpod(keepAlive: true)
IMoneyTrackerRepository moneyTrackerRepositoryRepo(Ref ref) {
  // Transactions are read once local storage has opened, like everything
  // else, so a failed start is reported in one place.
  if (ref.watch(sqlitePrefsProvider).valueOrNull == null) {
    throw StateError('Local storage is not ready yet.');
  }
  return MoneyTrackerRepository(ref.watch(localDatabaseServiceProvider));
}
