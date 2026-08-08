import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/domain/repositories/interfaces/i_transactions_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'transactions_repository.g.dart';

class TransactionsRepository implements ITransactionsRepository {
  TransactionsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _balanceKey = 'transactions_page_balance';
  static const String _transactionsKey = 'transactions_detail_list';

  @override
  Future<double> getTransactionsBalance() async {
    final balance = _prefs.getDouble(_balanceKey);
    if (balance != null) {
      return balance;
    }
    const defaultBalance = 2678.01;
    await _prefs.setDouble(_balanceKey, defaultBalance);
    return defaultBalance;
  }

  @override
  Future<List<TransactionDetailModel>> getTransactions() async {
    final rawJsonList = _prefs.getStringList(_transactionsKey);
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

    final defaultList = [
      const TransactionDetailModel(
        id: '1',
        title: 'Salary Payment',
        date: 'Today',
        amount: 120000,
        isIncome: true,
        currency: 'INR',
      ),
      const TransactionDetailModel(
        id: '2',
        title: 'Food',
        date: 'Today',
        amount: 120,
        isIncome: false,
        currency: 'INR',
      ),
      const TransactionDetailModel(
        id: '3',
        title: 'EMI Payment',
        date: 'Yesterday',
        amount: 760,
        isIncome: false,
        currency: 'INR',
      ),
      const TransactionDetailModel(
        id: '4',
        title: 'Petrol',
        date: '20-05-2026',
        amount: 180,
        isIncome: false,
        currency: 'INR',
      ),
    ];
    await saveTransactions(defaultList);
    return defaultList;
  }

  @override
  Future<void> saveTransactions(
      List<TransactionDetailModel> transactions,) async {
    final jsonList =
        transactions.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_transactionsKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
ITransactionsRepository transactionsRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized yet');
  }
  return TransactionsRepository(prefs);
}
