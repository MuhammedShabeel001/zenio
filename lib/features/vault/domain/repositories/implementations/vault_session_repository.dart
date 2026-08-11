import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/vault/domain/models/vault_card_session_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_session_model.dart';
import 'package:zenio/features/vault/domain/repositories/interfaces/i_vault_session_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'vault_session_repository.g.dart';

class VaultSessionRepository implements IVaultSessionRepository {
  VaultSessionRepository(this._prefs);

  final SharedPreferences? _prefs;

  static const String _cardsStorageKey = 'vault_card_sessions_list_v1';
  static const String _notesStorageKey = 'vault_note_sessions_list_v1';

  // --- Vault Card Sessions ---

  @override
  Future<List<VaultCardSessionModel>> getVaultCardSessions() async {
    final prefs = _prefs;
    if (prefs == null) return [];

    final rawList = prefs.getStringList(_cardsStorageKey);
    if (rawList != null && rawList.isNotEmpty) {
      try {
        return rawList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return VaultCardSessionModel.fromJson(map);
        }).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  @override
  Future<VaultCardSessionModel?> getVaultCardSessionById(String id) async {
    final sessions = await getVaultCardSessions();
    try {
      return sessions.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveVaultCardSession(VaultCardSessionModel card) async {
    final sessions = await getVaultCardSessions();
    final updatedList = [...sessions, card];
    await _saveCardList(updatedList);
  }

  @override
  Future<void> updateVaultCardSession(VaultCardSessionModel card) async {
    final sessions = await getVaultCardSessions();
    final updatedList = sessions.map((item) {
      return item.id == card.id ? card : item;
    }).toList();
    await _saveCardList(updatedList);
  }

  @override
  Future<void> deleteVaultCardSession(String id) async {
    final sessions = await getVaultCardSessions();
    final updatedList = sessions.where((item) => item.id != id).toList();
    await _saveCardList(updatedList);
  }

  @override
  Future<void> clearAllVaultCardSessions() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_cardsStorageKey);
  }

  Future<void> _saveCardList(List<VaultCardSessionModel> sessions) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonList =
        sessions.map((session) => jsonEncode(session.toJson())).toList();
    await prefs.setStringList(_cardsStorageKey, jsonList);
  }

  // --- Vault Note Sessions ---

  @override
  Future<List<VaultNoteSessionModel>> getVaultNoteSessions() async {
    final prefs = _prefs;
    if (prefs == null) return [];

    final rawList = prefs.getStringList(_notesStorageKey);
    if (rawList != null && rawList.isNotEmpty) {
      try {
        return rawList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return VaultNoteSessionModel.fromJson(map);
        }).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  @override
  Future<VaultNoteSessionModel?> getVaultNoteSessionById(String id) async {
    final sessions = await getVaultNoteSessions();
    try {
      return sessions.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveVaultNoteSession(VaultNoteSessionModel note) async {
    final sessions = await getVaultNoteSessions();
    final updatedList = [...sessions, note];
    await _saveNoteList(updatedList);
  }

  @override
  Future<void> updateVaultNoteSession(VaultNoteSessionModel note) async {
    final sessions = await getVaultNoteSessions();
    final updatedList = sessions.map((item) {
      return item.id == note.id ? note : item;
    }).toList();
    await _saveNoteList(updatedList);
  }

  @override
  Future<void> deleteVaultNoteSession(String id) async {
    final sessions = await getVaultNoteSessions();
    final updatedList = sessions.where((item) => item.id != id).toList();
    await _saveNoteList(updatedList);
  }

  @override
  Future<void> clearAllVaultNoteSessions() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove(_notesStorageKey);
  }

  Future<void> _saveNoteList(List<VaultNoteSessionModel> sessions) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonList =
        sessions.map((session) => jsonEncode(session.toJson())).toList();
    await prefs.setStringList(_notesStorageKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
IVaultSessionRepository vaultSessionRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return VaultSessionRepository(prefs);
}
