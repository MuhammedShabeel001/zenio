import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/features/analytics/domain/repositories/interfaces/i_analytics_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'analytics_repository.g.dart';

class AnalyticsRepository implements IAnalyticsRepository {
  AnalyticsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _balanceKey = 'analytics_balance';
  static const String _spendsKey = 'analytics_category_spends';

  @override
  Future<double> getAnalyticsBalance() async {
    final balance = _prefs.getDouble(_balanceKey);
    if (balance != null) {
      return balance;
    }
    const defaultBalance = 2678.01;
    await saveAnalyticsBalance(defaultBalance);
    return defaultBalance;
  }

  @override
  Future<List<CategorySpendModel>> getCategorySpends() async {
    final rawJsonList = _prefs.getStringList(_spendsKey);
    if (rawJsonList != null && rawJsonList.isNotEmpty) {
      try {
        return rawJsonList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return CategorySpendModel.fromJson(map);
        }).toList();
      } catch (_) {
        // Fallback to defaults
      }
    }

    final defaultSpends = [
      const CategorySpendModel(
        id: '1',
        name: 'Travel',
        amount: 3500,
        spendsCount: 12,
        colorHex: '0xFFFF771C',
        iconName: 'travel',
      ),
      const CategorySpendModel(
        id: '2',
        name: 'Entertainment',
        amount: 2800,
        spendsCount: 10,
        colorHex: '0xFF8C43E6',
        iconName: 'entertainment',
      ),
      const CategorySpendModel(
        id: '3',
        name: 'Loan',
        amount: 1800,
        spendsCount: 4,
        colorHex: '0xFF10B981',
        iconName: 'debt',
      ),
      const CategorySpendModel(
        id: '4',
        name: 'Food & Drink',
        amount: 1100,
        spendsCount: 15,
        colorHex: '0xFFFF4D4D',
        iconName: 'expense',
      ),
      const CategorySpendModel(
        id: '5',
        name: 'Shopping',
        amount: 500,
        spendsCount: 6,
        colorHex: '0xFF1DA1F2',
        iconName: 'card',
      ),
      const CategorySpendModel(
        id: '6',
        name: 'Grocery',
        amount: 300,
        spendsCount: 5,
        colorHex: '0xFF00C4DE',
        iconName: 'wallet',
      ),
    ];
    await saveCategorySpends(defaultSpends);
    return defaultSpends;
  }

  @override
  Future<void> saveAnalyticsBalance(double balance) async {
    await _prefs.setDouble(_balanceKey, balance);
  }

  @override
  Future<void> saveCategorySpends(List<CategorySpendModel> spends) async {
    final jsonList = spends.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_spendsKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
IAnalyticsRepository analyticsRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized yet');
  }
  return AnalyticsRepository(prefs);
}
