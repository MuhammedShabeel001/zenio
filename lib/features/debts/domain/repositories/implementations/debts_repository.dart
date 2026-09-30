import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/features/debts/domain/repositories/interfaces/i_debts_repository.dart';
import 'package:zenio/shared/providers/providers.dart';

part 'debts_repository.g.dart';

class DebtsRepository implements IDebtsRepository {
  DebtsRepository(this._prefs);

  final SqlitePrefs _prefs;

  static const String _debtsKey = 'debts_list_key_v2';

  @override
  Future<double> getDebtsBalance() async {
    final debts = await getDebts();
    var balance = 0.0;
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
  Future<List<DebtModel>> getDebts() {
    return _prefs.readJsonList(_debtsKey, DebtModel.fromJson);
  }

  @override
  Future<void> saveDebts(List<DebtModel> debts) async {
    final jsonList = debts.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_debtsKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
IDebtsRepository debtsRepositoryRepo(Ref ref) {
  final prefs = ref.watch(sqlitePrefsProvider).valueOrNull;
  if (prefs == null) {
    throw StateError('Local storage is not ready yet.');
  }
  return DebtsRepository(prefs);
}
