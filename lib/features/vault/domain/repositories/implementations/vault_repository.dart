import 'package:zenio/shared/providers/providers.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';
import 'package:zenio/features/vault/domain/repositories/interfaces/i_vault_repository.dart';

part 'vault_repository.g.dart';

const List<VaultCardModel> defaultVaultCards = [];

const List<VaultNoteModel> defaultVaultNotes = [];

class VaultRepository implements IVaultRepository {
  VaultRepository(this._prefs);

  final SqlitePrefs? _prefs;

  static const String _cardsKey = 'vault_cards_list_v2';
  static const String _notesKey = 'vault_notes_list_v2';

  @override
  Future<List<VaultCardModel>> getCards() async {
    final prefs = _prefs;
    if (prefs == null) return defaultVaultCards;

    final rawJsonList = prefs.getStringList(_cardsKey);
    if (rawJsonList != null && rawJsonList.isNotEmpty) {
      try {
        return rawJsonList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return VaultCardModel.fromJson(map);
        }).toList();
      } catch (_) {
        // Fallback
      }
    }

    await saveCards(defaultVaultCards);
    return defaultVaultCards;
  }

  @override
  Future<void> saveCards(List<VaultCardModel> cards) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonList = cards.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_cardsKey, jsonList);
  }

  @override
  Future<List<VaultNoteModel>> getNotes() async {
    final prefs = _prefs;
    if (prefs == null) return defaultVaultNotes;

    final rawJsonList = prefs.getStringList(_notesKey);
    if (rawJsonList != null && rawJsonList.isNotEmpty) {
      try {
        return rawJsonList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return VaultNoteModel.fromJson(map);
        }).toList();
      } catch (_) {
        // Fallback
      }
    }

    await saveNotes(defaultVaultNotes);
    return defaultVaultNotes;
  }

  @override
  Future<void> saveNotes(List<VaultNoteModel> notes) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonList = notes.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_notesKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
IVaultRepository vaultRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sqlitePrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return VaultRepository(prefs);
}
