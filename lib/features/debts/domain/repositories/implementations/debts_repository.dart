import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/features/debts/domain/repositories/interfaces/i_debts_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'debts_repository.g.dart';

const List<DebtModel> defaultDebtsList = [
  DebtModel(
    id: '1',
    personName: 'Majid',
    date: '12 June 2026',
    amount: 120,
    currency: 'INR',
    isOwed: true,
    iconName: 'up_arrow',
  ),
  DebtModel(
    id: '2',
    personName: 'Majid',
    date: '12 June 2026',
    amount: 120,
    currency: 'INR',
    isOwed: true,
    iconName: 'up_arrow',
  ),
  DebtModel(
    id: '3',
    personName: 'Alex',
    date: '08 June 2026',
    amount: 450,
    currency: 'INR',
    isOwed: true,
    iconName: 'up_arrow',
  ),
  DebtModel(
    id: '4',
    personName: 'Sarah',
    date: '02 June 2026',
    amount: 850,
    currency: 'INR',
    isOwed: true,
    iconName: 'up_arrow',
  ),
  DebtModel(
    id: '5',
    personName: 'Rahul',
    date: '28 May 2026',
    amount: 1200,
    currency: 'INR',
    isOwed: true,
    iconName: 'up_arrow',
  ),
  DebtModel(
    id: '6',
    personName: 'David',
    date: '20 May 2026',
    amount: 340,
    currency: 'INR',
    isOwed: true,
    iconName: 'up_arrow',
  ),
];

class DebtsRepository implements IDebtsRepository {
  DebtsRepository(this._prefs);

  final SharedPreferences? _prefs;

  static const String _balanceKey = 'debts_page_balance_v1';
  static const String _debtsKey = 'debts_list_key_v1';

  @override
  Future<double> getDebtsBalance() async {
    final prefs = _prefs;
    if (prefs == null) return -268.01;
    final balance = prefs.getDouble(_balanceKey);
    if (balance != null) {
      return balance;
    }
    const defaultBalance = -268.01;
    await prefs.setDouble(_balanceKey, defaultBalance);
    return defaultBalance;
  }

  @override
  Future<List<DebtModel>> getDebts() async {
    final prefs = _prefs;
    if (prefs == null) return defaultDebtsList;

    final rawJsonList = prefs.getStringList(_debtsKey);
    if (rawJsonList != null && rawJsonList.isNotEmpty) {
      try {
        return rawJsonList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return DebtModel.fromJson(map);
        }).toList();
      } catch (_) {
        // Fallback to defaults
      }
    }

    await saveDebts(defaultDebtsList);
    return defaultDebtsList;
  }

  @override
  Future<void> saveDebts(List<DebtModel> debts) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonList = debts.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_debtsKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
IDebtsRepository debtsRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return DebtsRepository(prefs);
}
