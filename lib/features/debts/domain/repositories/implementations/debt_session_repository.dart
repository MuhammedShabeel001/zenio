import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/debts/domain/models/debt_session_model.dart';
import 'package:zenio/features/debts/domain/repositories/interfaces/i_debt_session_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'debt_session_repository.g.dart';

class DebtSessionRepository implements IDebtSessionRepository {
  DebtSessionRepository(this._prefs);

  final SharedPreferences? _prefs;

  static const String _storageKey = 'debt_sessions_list_v1';

  @override
  Future<List<DebtSessionModel>> getDebtSessions() async {
    final prefs = _prefs;
    if (prefs == null) return [];

    final rawList = prefs.getStringList(_storageKey);
    if (rawList != null && rawList.isNotEmpty) {
      try {
        return rawList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return DebtSessionModel.fromJson(map);
        }).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  @override
  Future<DebtSessionModel?> getDebtSessionById(String id) async {
    final sessions = await getDebtSessions();
    try {
      return sessions.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDebtSession(DebtSessionModel debt) async {
    final sessions = await getDebtSessions();
    final updatedList = [...sessions, debt];
    await _saveList(updatedList);
  }

  @override
  Future<void> updateDebtSession(DebtSessionModel debt) async {
    final sessions = await getDebtSessions();
    final updatedList = sessions.map((item) {
      return item.id == debt.id ? debt : item;
    }).toList();
    await _saveList(updatedList);
  }

  @override
  Future<void> deleteDebtSession(String id) async {
    final sessions = await getDebtSessions();
    final updatedList = sessions.where((item) => item.id != id).toList();
    await _saveList(updatedList);
  }

  @override
  Future<void> clearAllDebtSessions() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_storageKey);
  }

  Future<void> _saveList(List<DebtSessionModel> sessions) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonList =
        sessions.map((session) => jsonEncode(session.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
IDebtSessionRepository debtSessionRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return DebtSessionRepository(prefs);
}
