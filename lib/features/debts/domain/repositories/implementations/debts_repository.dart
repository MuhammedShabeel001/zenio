import 'package:zenio/shared/providers/providers.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/features/debts/domain/repositories/interfaces/i_debts_repository.dart';

part 'debts_repository.g.dart';

const List<DebtModel> defaultDebtsList = [];

class DebtsRepository implements IDebtsRepository {
  DebtsRepository(this._prefs);

  final SqlitePrefs? _prefs;

  static const String _balanceKey = 'debts_page_balance_v2';
  static const String _debtsKey = 'debts_list_key_v2';

  @override
  Future<double> getDebtsBalance() async {
    final debts = await getDebts();
    double balance = 0.0;
    for (final debt in debts) {
      if (debt.isOwed) {
        balance -= debt.amount;
      } else {
        balance += debt.amount;
      }
    }
    return balance;
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
  final prefsAsync = ref.watch(sqlitePrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return DebtsRepository(prefs);
}
