import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';

abstract class IVaultRepository {
  Future<List<VaultCardModel>> getCards();
  Future<void> saveCards(List<VaultCardModel> cards);
  Future<List<VaultNoteModel>> getNotes();
  Future<void> saveNotes(List<VaultNoteModel> notes);
}
