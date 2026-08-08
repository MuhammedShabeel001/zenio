import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/domain/repositories/interfaces/i_transactions_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'transactions_repository.g.dart';

const List<TransactionDetailModel> defaultTransactionsList = [
  TransactionDetailModel(
    id: '1',
    title: 'Salary Payment',
    date: 'Today',
    amount: 120000,
    isIncome: true,
    currency: 'INR',
  ),
  TransactionDetailModel(
    id: '2',
    title: 'Food & Coffee',
    date: 'Today',
    amount: 120,
    isIncome: false,
    currency: 'INR',
  ),
  TransactionDetailModel(
    id: '3',
    title: 'EMI Payment',
    date: 'Yesterday',
    amount: 760,
    isIncome: false,
    currency: 'INR',
  ),
  TransactionDetailModel(
    id: '4',
    title: 'Petrol',
    date: '20-05-2026',
    amount: 180,
    isIncome: false,
    currency: 'INR',
  ),
  TransactionDetailModel(
    id: '5',
    title: 'Freelance Payout',
    date: '18-05-2026',
    amount: 15000,
    isIncome: true,
    currency: 'INR',
  ),
  TransactionDetailModel(
    id: '6',
    title: 'Grocery Shopping',
    date: '16-05-2026',
    amount: 2450,
    isIncome: false,
    currency: 'INR',
  ),
  TransactionDetailModel(
    id: '7',
    title: 'Dinner Outing',
    date: '15-05-2026',
    amount: 1100,
    isIncome: false,
    currency: 'INR',
  ),
  TransactionDetailModel(
    id: '8',
    title: 'Electricity Bill',
    date: '12-05-2026',
    amount: 890,
    isIncome: false,
    currency: 'INR',
  ),
  TransactionDetailModel(
    id: '9',
    title: 'Investment Return',
    date: '10-05-2026',
    amount: 4500,
    isIncome: true,
    currency: 'INR',
  ),
  TransactionDetailModel(
    id: '10',
    title: 'Movie Tickets',
    date: '08-05-2026',
    amount: 450,
    isIncome: false,
    currency: 'INR',
  ),
];

class TransactionsRepository implements ITransactionsRepository {
  TransactionsRepository(this._prefs);

  final SharedPreferences? _prefs;

  static const String _balanceKey = 'transactions_page_balance_v3';
  static const String _transactionsKey = 'transactions_detail_list_v3';

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
}

@Riverpod(keepAlive: true)
ITransactionsRepository transactionsRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return TransactionsRepository(prefs);
}
