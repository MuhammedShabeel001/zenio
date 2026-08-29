import 'package:zenio/shared/providers/providers.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/transactions/domain/models/transaction_session_model.dart';
import 'package:zenio/features/transactions/domain/repositories/interfaces/i_transaction_session_repository.dart';

part 'transaction_session_repository.g.dart';

class TransactionSessionRepository implements ITransactionSessionRepository {
  TransactionSessionRepository(this._prefs);

  final SqlitePrefs? _prefs;

  static const String _storageKey = 'transaction_sessions_list_v1';

  @override
  Future<List<TransactionSessionModel>> getTransactionSessions() async {
    final prefs = _prefs;
    if (prefs == null) return [];

    final rawList = prefs.getStringList(_storageKey);
    if (rawList != null && rawList.isNotEmpty) {
      try {
        return rawList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return TransactionSessionModel.fromJson(map);
        }).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  @override
  Future<TransactionSessionModel?> getTransactionSessionById(String id) async {
    final sessions = await getTransactionSessions();
    try {
      return sessions.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTransactionSession(
    TransactionSessionModel transaction,
  ) async {
    final sessions = await getTransactionSessions();
    final updatedList = [...sessions, transaction];
    await _saveList(updatedList);
  }

  @override
  Future<void> updateTransactionSession(
    TransactionSessionModel transaction,
  ) async {
    final sessions = await getTransactionSessions();
    final updatedList = sessions.map((item) {
      return item.id == transaction.id ? transaction : item;
    }).toList();
    await _saveList(updatedList);
  }

  @override
  Future<void> deleteTransactionSession(String id) async {
    final sessions = await getTransactionSessions();
    final updatedList = sessions.where((item) => item.id != id).toList();
    await _saveList(updatedList);
  }

  @override
  Future<void> clearAllTransactionSessions() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_storageKey);
  }

  Future<void> _saveList(List<TransactionSessionModel> sessions) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonList =
        sessions.map((session) => jsonEncode(session.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
ITransactionSessionRepository transactionSessionRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sqlitePrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return TransactionSessionRepository(prefs);
}
