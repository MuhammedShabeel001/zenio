import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';
import 'package:zenio/features/vault/domain/repositories/interfaces/i_vault_repository.dart';
import 'package:zenio/shared/providers/providers.dart';
import 'package:zenio/shared/services/secure_key_value_store.dart';
import 'package:zenio/shared/utils/json_list_codec.dart';

part 'vault_repository.g.dart';

/// Stores vault cards and notes in secure storage.
///
/// Older versions kept them as plain text in SQLite. The first access moves
/// that data across: copy, read back and verify, record the move, and only
/// then delete the plain text. An interrupted move resumes on the next launch,
/// and if secure storage is unavailable the vault keeps working from the
/// existing data, so nothing is lost either way.
class VaultRepository implements IVaultRepository {
  VaultRepository(this._prefs, this._secure, this._db);

  final SqlitePrefs _prefs;
  final SecureKeyValueStore _secure;
  final LocalDatabaseService _db;

  /// Written to SQLite once the vault lives in secure storage. Secure entries
  /// without it are leftovers from an earlier install (the iOS Keychain
  /// survives uninstalling the app) and are discarded.
  @visibleForTesting
  static const String migratedMarkerKey = 'vault_secure_storage_v1';

  static const String _legacyCardsKey = 'vault_cards_list_v2';
  static const String _legacyNotesKey = 'vault_notes_list_v2';
  static const String _cardsKey = 'vault.cards';
  static const String _notesKey = 'vault.notes';

  /// Every plain-text key that may hold vault data, and its secure key.
  /// Includes preserved unreadable entries and the old session lists, which
  /// can contain card details too.
  @visibleForTesting
  static const Map<String, String> legacyToSecureKeys = {
    _legacyCardsKey: _cardsKey,
    _legacyNotesKey: _notesKey,
    '$_legacyCardsKey$unreadableKeySuffix': '$_cardsKey$unreadableKeySuffix',
    '$_legacyNotesKey$unreadableKeySuffix': '$_notesKey$unreadableKeySuffix',
    'vault_card_sessions_list_v1': 'vault.legacy_card_sessions',
    'vault_note_sessions_list_v1': 'vault.legacy_note_sessions',
  };

  /// Resolves to true when secure storage is in use for this session.
  Future<bool>? _secureStorageReady;

  @override
  Future<void> migrateToSecureStorage() => _useSecureStorage();

  Future<bool> _useSecureStorage() => _secureStorageReady ??= _migrate();

  Future<bool> _migrate() async {
    try {
      if (_prefs.getString(migratedMarkerKey) == null) {
        await _copyLegacyToSecure();
        await _prefs.setString(migratedMarkerKey, 'done');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Vault: secure storage unavailable, using existing data '
            'for now ($error)');
      }
      return false;
    }

    // The secure copy is verified and recorded; the plain text can go. A
    // failure here is retried on the next launch.
    try {
      await _deleteLegacyPlaintext();
    } catch (_) {}
    return true;
  }

  Future<void> _copyLegacyToSecure() async {
    for (final entry in legacyToSecureKeys.entries) {
      final plaintext = _prefs.getString(entry.key);
      if (plaintext == null) {
        // Nothing to move, so anything already there is a leftover.
        await _secure.delete(entry.value);
        continue;
      }
      await _secure.write(entry.value, plaintext);
      if (await _secure.read(entry.value) != plaintext) {
        throw StateError('Could not verify the secure copy of ${entry.key}.');
      }
    }
  }

  Future<void> _deleteLegacyPlaintext() async {
    var removed = false;
    for (final key in legacyToSecureKeys.keys) {
      if (_prefs.containsKey(key)) {
        await _prefs.remove(key);
        removed = true;
      }
    }
    // Deleted rows can linger in free database pages until a VACUUM.
    if (removed) await _db.vacuum();
  }

  @override
  Future<List<VaultCardModel>> getCards() {
    return _readList(_cardsKey, _legacyCardsKey, VaultCardModel.fromJson);
  }

  @override
  Future<void> saveCards(List<VaultCardModel> cards) {
    return _writeList(
      _cardsKey,
      _legacyCardsKey,
      cards.map((card) => card.toJson()),
    );
  }

  @override
  Future<List<VaultNoteModel>> getNotes() {
    return _readList(_notesKey, _legacyNotesKey, VaultNoteModel.fromJson);
  }

  @override
  Future<void> saveNotes(List<VaultNoteModel> notes) {
    return _writeList(
      _notesKey,
      _legacyNotesKey,
      notes.map((note) => note.toJson()),
    );
  }

  Future<List<T>> _readList<T>(
    String secureKey,
    String legacyKey,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    if (!await _useSecureStorage()) {
      return _prefs.readJsonList(legacyKey, fromJson);
    }
    final raw = await _secure.read(secureKey);
    if (raw == null) return [];
    final decoded = decodeJsonList(raw, fromJson);
    if (decoded.unreadable.isNotEmpty) {
      // Keep entries that cannot be read, so a later save cannot drop them.
      final backupKey = '$secureKey$unreadableKeySuffix';
      final existing = await _secure.read(backupKey);
      final merged = mergeUnreadable(
        existing == null ? const [] : decodeStringList(existing),
        decoded.unreadable,
      );
      if (merged != null) {
        await _secure.write(backupKey, encodeStringList(merged));
      }
    }
    return decoded.items;
  }

  Future<void> _writeList(
    String secureKey,
    String legacyKey,
    Iterable<Map<String, dynamic>> items,
  ) async {
    final raw = encodeJsonList(items);
    if (await _useSecureStorage()) {
      await _secure.write(secureKey, raw);
      return;
    }
    // Secure storage is unavailable. Existing entries can still be removed,
    // but new or changed card details are never written as plain text.
    final stored = decodeStringList(_prefs.getString(legacyKey) ?? '[]');
    final onlyRemoves =
        decodeStringList(raw).every((entry) => stored.contains(entry));
    if (!onlyRemoves) throw const VaultUnavailableException();
    await _prefs.setString(legacyKey, raw);
  }

  @override
  Future<void> clearAll() async {
    try {
      for (final secureKey in legacyToSecureKeys.values) {
        await _secure.delete(secureKey);
      }
    } catch (_) {
      // The key store may be unusable; wipe it the forceful way instead.
      await _secure.deleteAllForcibly();
    }
    for (final legacyKey in legacyToSecureKeys.keys) {
      await _prefs.remove(legacyKey);
    }
    await _prefs.remove(migratedMarkerKey);
    _secureStorageReady = null;
  }
}

@Riverpod(keepAlive: true)
IVaultRepository vaultRepositoryRepo(Ref ref) {
  final prefs = ref.watch(sqlitePrefsProvider).valueOrNull;
  if (prefs == null) {
    throw StateError('Local storage is not ready yet.');
  }
  return VaultRepository(
    prefs,
    ref.watch(secureKeyValueStoreProvider),
    ref.watch(localDatabaseServiceProvider),
  );
}

/// The Vault's secure storage is unavailable on this device right now.
class VaultUnavailableException implements Exception {
  const VaultUnavailableException();

  @override
  String toString() =>
      "The Vault can't save right now because secure storage is unavailable.";
}
