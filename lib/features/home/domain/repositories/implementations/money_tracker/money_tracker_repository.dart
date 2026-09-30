import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/interfaces/money_tracker/i_money_tracker_repository.dart';
import 'package:zenio/features/wallet/domain/wallet_balances.dart';
import 'package:zenio/shared/providers/providers.dart';
import 'package:zenio/shared/utils/money_limits.dart';

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
        final transaction = TransactionModel.fromJson(_fromRow(map));
        // An amount no version should have stored (NaN or an infinity)
        // would break every total and list it reached.
        checkReadableAmount(transaction.amount, 'transaction amount');
        transactions.add(transaction);
      } catch (error) {
        // Leave the row in the database, unchanged; it is simply not shown
        // or counted.
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
      final title = row['title']! as String;
      final bankName = row['bank_name'] as String?;
      final renamed = renamedWalletReferences(
        kind: resolveTransactionKind(
          kind: row['kind'] as String?,
          title: title,
          bankName: bankName,
          isIncome: row['is_income'] == 1,
        ),
        title: title,
        bankName: bankName,
        transferFrom: row['transfer_from'] as String?,
        transferTo: row['transfer_to'] as String?,
        oldName: oldName,
        newName: newName,
      );
      if (renamed == null) return null;
      return {
        'title': renamed.title,
        'bank_name': renamed.bankName,
        'transfer_from': renamed.transferFrom,
        'transfer_to': renamed.transferTo,
      };
    });
  }

  /// SQLite stores booleans as 0/1.
  static Map<String, dynamic> _fromRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    final isIncome = map['is_income'];
    map['is_income'] = isIncome == 1 || isIncome == true;
    return map;
  }

  /// [transaction] as a database row.
  static Map<String, dynamic> toRow(TransactionModel transaction) =>
      _toRow(transaction);

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
