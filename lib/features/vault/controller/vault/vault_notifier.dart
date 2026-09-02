import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/vault/controller/vault/vault_state.dart';
import 'package:zenio/features/vault/domain/repositories/implementations/vault_repository.dart';
import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';

part 'vault_notifier.g.dart';

@Riverpod(keepAlive: true)
class VaultNotifier extends _$VaultNotifier {
  @override
  VaultState build() {
    _loadData();
    return VaultState.initial();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(vaultRepositoryRepoProvider);
      final cardsList = await repo.getCards();
      final notesList = await repo.getNotes();
      state = state.copyWith(
        cards: cardsList,
        notes: notesList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setMode(VaultMode mode) {
    state = state.copyWith(mode: mode);
  }

  Future<void> deleteCard(String id) async {
    final updated = state.cards.where((c) => c.id != id).toList();
    final repo = ref.read(vaultRepositoryRepoProvider);
    await repo.saveCards(updated);
    state = state.copyWith(cards: updated);
  }

  Future<void> deleteNote(String id) async {
    final updated = state.notes.where((n) => n.id != id).toList();
    final repo = ref.read(vaultRepositoryRepoProvider);
    await repo.saveNotes(updated);
    state = state.copyWith(notes: updated);
  }
  Future<void> addCard(VaultCardModel card) async {
    final updated = List<VaultCardModel>.from(state.cards)..add(card);
    final repo = ref.read(vaultRepositoryRepoProvider);
    await repo.saveCards(updated);
    state = state.copyWith(cards: updated);
  }

  Future<void> addNote(VaultNoteModel note) async {
    final updated = List<VaultNoteModel>.from(state.notes)..add(note);
    final repo = ref.read(vaultRepositoryRepoProvider);
    await repo.saveNotes(updated);
    state = state.copyWith(notes: updated);
  }
}
