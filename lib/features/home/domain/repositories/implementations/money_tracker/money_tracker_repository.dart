import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/domain/models/summary/financial_summary_model.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/interfaces/money_tracker/i_money_tracker_repository.dart';
import 'package:zenio/shared/services/local_database_service.dart';
import 'package:zenio/shared/providers/providers.dart';

part 'money_tracker_repository.g.dart';

class MoneyTrackerRepository implements IMoneyTrackerRepository {
  MoneyTrackerRepository(this._prefs, this._dbService);

  final SqlitePrefs _prefs;
  final LocalDatabaseService _dbService;

  static const String _summaryKey = 'money_tracker_summary_v2';

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
      totalBalance: 0.0,
      income: 0.0,
      incomeChangePercentage: 0.0,
      expense: 0.0,
      expenseChangePercentage: 0.0,
      selectedCurrency: 'INR',
    );
    await saveSummary(defaultSummary);
    return defaultSummary;
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final maps = await _dbService.getTransactionsMap();
      if (maps.isNotEmpty) {
        return maps.map((map) {
          // SQL boolean is stored as integer (1/0)
          final modMap = Map<String, dynamic>.from(map);
          modMap['is_income'] = (modMap['is_income'] as int) == 1;
          return TransactionModel.fromJson(modMap);
        }).toList();
      }
    } catch (_) {}

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
    final maps = transactions.map((tx) {
      final map = tx.toJson();
      map['is_income'] = (map['is_income'] as bool) ? 1 : 0;
      return map;
    }).toList();
    await _dbService.saveTransactionsList(maps);
  }
}

@Riverpod(keepAlive: true)
IMoneyTrackerRepository moneyTrackerRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sqlitePrefsProvider);
  final dbService = ref.watch(localDatabaseServiceProvider);
  final prefs = prefsAsync.valueOrNull;
  if (prefs == null) {
    throw Exception('SqlitePrefs not initialized yet');
  }
  return MoneyTrackerRepository(prefs, dbService);
}
