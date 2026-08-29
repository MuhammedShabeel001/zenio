import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/domain/repositories/interfaces/i_transactions_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'transactions_repository.g.dart';

const List<TransactionDetailModel> defaultTransactionsList = [];

class TransactionsRepository implements ITransactionsRepository {
  TransactionsRepository(this._prefs);

  final SharedPreferences? _prefs;

  static const String _balanceKey = 'transactions_page_balance_v4';
  static const String _transactionsKey = 'app_unified_transactions_v1';

  @override
  Future<double> getTransactionsBalance() async {
    final prefs = _prefs;
    if (prefs == null) return 2678.01;
    final balance = prefs.getDouble(_balanceKey);
    if (balance != null) {
      return balance;
    }
    const defaultBalance = 2678.01;
    await prefs.setDouble(_balanceKey, defaultBalance);
    return defaultBalance;
  }

  @override
  Future<List<TransactionDetailModel>> getTransactions() async {
    final prefs = _prefs;
    if (prefs == null) return defaultTransactionsList;

    final rawJsonList = prefs.getStringList(_transactionsKey);
    if (rawJsonList != null && rawJsonList.isNotEmpty) {
      try {
        return rawJsonList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return TransactionDetailModel.fromJson(map);
        }).toList();
      } catch (_) {
        // Fallback to default
      }
    }

    await saveTransactions(defaultTransactionsList);
    return defaultTransactionsList;
  }

  @override
  Future<void> saveTransactions(
    List<TransactionDetailModel> transactions,
  ) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonList =
        transactions.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_transactionsKey, jsonList);
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
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return TransactionsRepository(prefs);
}
