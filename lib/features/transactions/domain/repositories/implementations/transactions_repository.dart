import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/domain/repositories/interfaces/i_transactions_repository.dart';
import 'package:zenio/shared/providers/providers.dart';

part 'transactions_repository.g.dart';

const List<TransactionDetailModel> defaultTransactionsList = [];

class TransactionsRepository implements ITransactionsRepository {
  TransactionsRepository(this._prefs, this._dbService);

  final SqlitePrefs? _prefs;
  final LocalDatabaseService _dbService;

  static const String _balanceKey = 'transactions_page_balance_v4';

  @override
  Future<double> getTransactionsBalance() async {
    final prefs = _prefs;
    if (prefs == null) return 0.0;
    final balance = prefs.getDouble(_balanceKey);
    if (balance != null) {
      return balance;
    }
    const defaultBalance = 0.0;
    await prefs.setDouble(_balanceKey, defaultBalance);
    return defaultBalance;
  }

  @override
  Future<List<TransactionDetailModel>> getTransactions() async {
    try {
      final maps = await _dbService.getTransactionsMap();
      if (maps.isNotEmpty) {
        return maps.map((map) {
          final modMap = Map<String, dynamic>.from(map);
          modMap['is_income'] = (modMap['is_income'] as int) == 1;
          return TransactionDetailModel.fromJson(modMap);
        }).toList();
      }
    } catch (_) {}

    await saveTransactions(defaultTransactionsList);
    return defaultTransactionsList;
  }

  @override
  Future<void> saveTransactions(
    List<TransactionDetailModel> transactions,
  ) async {
    final maps = transactions.map((item) {
      final map = item.toJson();
      map['is_income'] = (map['is_income'] as bool) ? 1 : 0;
      return map;
    }).toList();
    await _dbService.saveTransactionsList(maps);
  }

  @override
  Future<void> saveTransactionsBalance(double balance) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setDouble(_balanceKey, balance);
  }
}

@Riverpod(keepAlive: true)
ITransactionsRepository transactionsRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sqlitePrefsProvider);
  final dbService = ref.watch(localDatabaseServiceProvider);
  final prefs = prefsAsync.valueOrNull;
  return TransactionsRepository(prefs, dbService);
}
