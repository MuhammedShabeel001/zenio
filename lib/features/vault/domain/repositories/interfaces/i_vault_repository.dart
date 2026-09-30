import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';

abstract class IVaultRepository {
  /// Moves vault data that is still stored in plain text into secure storage.
  /// Safe to call repeatedly; later calls reuse the first result.
  Future<void> migrateToSecureStorage();

  Future<List<VaultCardModel>> getCards();
  Future<void> saveCards(List<VaultCardModel> cards);
  Future<List<VaultNoteModel>> getNotes();
  Future<void> saveNotes(List<VaultNoteModel> notes);

  /// Removes every vault entry, wherever it is stored.
  Future<void> clearAll();
}
