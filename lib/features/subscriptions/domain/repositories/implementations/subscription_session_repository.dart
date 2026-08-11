import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_session_model.dart';
import 'package:zenio/features/subscriptions/domain/repositories/interfaces/i_subscription_session_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'subscription_session_repository.g.dart';

class SubscriptionSessionRepository implements ISubscriptionSessionRepository {
  SubscriptionSessionRepository(this._prefs);

  final SharedPreferences? _prefs;

  static const String _storageKey = 'subscription_sessions_list_v1';

  @override
  Future<List<SubscriptionSessionModel>> getSubscriptionSessions() async {
    final prefs = _prefs;
    if (prefs == null) return [];

    final rawList = prefs.getStringList(_storageKey);
    if (rawList != null && rawList.isNotEmpty) {
      try {
        return rawList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return SubscriptionSessionModel.fromJson(map);
        }).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  @override
  Future<SubscriptionSessionModel?> getSubscriptionSessionById(
    String id,
  ) async {
    final sessions = await getSubscriptionSessions();
    try {
      return sessions.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSubscriptionSession(
    SubscriptionSessionModel subscription,
  ) async {
    final sessions = await getSubscriptionSessions();
    final updatedList = [...sessions, subscription];
    await _saveList(updatedList);
  }

  @override
  Future<void> updateSubscriptionSession(
    SubscriptionSessionModel subscription,
  ) async {
    final sessions = await getSubscriptionSessions();
    final updatedList = sessions.map((item) {
      return item.id == subscription.id ? subscription : item;
    }).toList();
    await _saveList(updatedList);
  }

  @override
  Future<void> deleteSubscriptionSession(String id) async {
    final sessions = await getSubscriptionSessions();
    final updatedList = sessions.where((item) => item.id != id).toList();
    await _saveList(updatedList);
  }

  @override
  Future<void> clearAllSubscriptionSessions() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_storageKey);
  }

  Future<void> _saveList(List<SubscriptionSessionModel> sessions) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonList =
        sessions.map((session) => jsonEncode(session.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
ISubscriptionSessionRepository subscriptionSessionRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return SubscriptionSessionRepository(prefs);
}
