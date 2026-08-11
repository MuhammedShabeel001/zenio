import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/wallet/domain/models/wallet_session_model.dart';
import 'package:zenio/features/wallet/domain/repositories/interfaces/i_wallet_session_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'wallet_session_repository.g.dart';

class WalletSessionRepository implements IWalletSessionRepository {
  WalletSessionRepository(this._prefs);

  final SharedPreferences? _prefs;

  static const String _storageKey = 'wallet_sessions_list_v1';

  @override
  String generate16DigitWalletId() {
    final random = Random.secure();
    final buffer = StringBuffer();
    // First digit 1-9 to avoid leading zero
    buffer.write(random.nextInt(9) + 1);
    for (var i = 0; i < 15; i++) {
      buffer.write(random.nextInt(10));
    }
    return buffer.toString();
  }

  @override
  Future<List<WalletSessionModel>> getWalletSessions() async {
    final prefs = _prefs;
    if (prefs == null) return [];

    final rawList = prefs.getStringList(_storageKey);
    if (rawList != null && rawList.isNotEmpty) {
      try {
        return rawList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return WalletSessionModel.fromJson(map);
        }).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  @override
  Future<WalletSessionModel?> getWalletSessionById(String walletId) async {
    final sessions = await getWalletSessions();
    try {
      return sessions.firstWhere((element) => element.walletId == walletId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveWalletSession(WalletSessionModel wallet) async {
    final sessions = await getWalletSessions();
    final updatedList = [...sessions, wallet];
    await _saveList(updatedList);
  }

  @override
  Future<void> updateWalletSession(WalletSessionModel wallet) async {
    final sessions = await getWalletSessions();
    final updatedList = sessions.map((item) {
      return item.walletId == wallet.walletId ? wallet : item;
    }).toList();
    await _saveList(updatedList);
  }

  @override
  Future<void> deleteWalletSession(String walletId) async {
    final sessions = await getWalletSessions();
    final updatedList =
        sessions.where((item) => item.walletId != walletId).toList();
    await _saveList(updatedList);
  }

  @override
  Future<void> toggleFreezeWalletSession(String walletId) async {
    final sessions = await getWalletSessions();
    final updatedList = sessions.map((item) {
      if (item.walletId == walletId) {
        return item.copyWith(isFreezed: !item.isFreezed);
      }
      return item;
    }).toList();
    await _saveList(updatedList);
  }

  @override
  Future<void> clearAllWalletSessions() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_storageKey);
  }

  Future<void> _saveList(List<WalletSessionModel> sessions) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonList =
        sessions.map((session) => jsonEncode(session.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
IWalletSessionRepository walletSessionRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return WalletSessionRepository(prefs);
}
