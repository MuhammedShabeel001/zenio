import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/home/domain/models/summary/financial_summary_model.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/interfaces/money_tracker/i_money_tracker_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'money_tracker_repository.g.dart';

class MoneyTrackerRepository implements IMoneyTrackerRepository {
  MoneyTrackerRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _summaryKey = 'money_tracker_summary_v2';
  static const String _transactionsKey = 'app_unified_transactions_v1';

  @override
  Future<FinancialSummaryModel> getSummary() async {
    final rawJson = _prefs.getString(_summaryKey);
    if (rawJson != null) {
      try {
        final map = jsonDecode(rawJson) as Map<String, dynamic>;
        return FinancialSummaryModel.fromJson(map);
      } catch (_) {
        // Fallback to initial default data on decode error
      }
    }

    const defaultSummary = FinancialSummaryModel(
      totalBalance: 23678.01,
      income: 23678.01,
      incomeChangePercentage: 12.06,
      expense: 23678.01,
      expenseChangePercentage: 12.06,
      selectedCurrency: 'INR',
    );
    await saveSummary(defaultSummary);
    return defaultSummary;
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final rawJsonList = _prefs.getStringList(_transactionsKey);
    if (rawJsonList != null && rawJsonList.isNotEmpty) {
      try {
        return rawJsonList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return TransactionModel.fromJson(map);
        }).toList();
      } catch (_) {
        // Fallback to initial default data on decode error
      }
    }

    final defaultTransactions = <TransactionModel>[];
    await saveTransactions(defaultTransactions);
    return defaultTransactions;
  }

  @override
  Future<void> saveSummary(FinancialSummaryModel summary) async {
    await _prefs.setString(_summaryKey, jsonEncode(summary.toJson()));
  }

  @override
  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final jsonList =
        transactions.map((tx) => jsonEncode(tx.toJson())).toList();
    await _prefs.setStringList(_transactionsKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
IMoneyTrackerRepository moneyTrackerRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized yet');
  }
  return MoneyTrackerRepository(prefs);
}
