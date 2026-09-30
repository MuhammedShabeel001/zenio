import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/vault/controller/vault/vault_state.dart';
import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';
import 'package:zenio/features/vault/domain/repositories/implementations/vault_repository.dart';
import 'package:zenio/features/vault/domain/repositories/interfaces/i_vault_repository.dart';
import 'package:zenio/shared/utils/serial_task_queue.dart';

part 'vault_notifier.g.dart';

@Riverpod(keepAlive: true)
class VaultNotifier extends _$VaultNotifier {
  IVaultRepository? _repository;
  Future<void>? _initialLoad;
  final _writes = SerialTaskQueue();

  @override
  VaultState build() {
    try {
      _repository = ref.watch(vaultRepositoryRepoProvider);
      _initialLoad = Future.microtask(_loadData);
    } catch (_) {
      // Local storage is still opening; this notifier rebuilds once it is.
      _repository = null;
      _initialLoad = null;
    }
    return VaultState.initial();
  }

  Future<void> _loadData() async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final cardsList = await repo.getCards();
      final notesList = await repo.getNotes();
      state = state.copyWith(
        cards: cardsList,
        notes: notesList,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadData() async => _loadData();

  void setMode(VaultMode mode) {
    state = state.copyWith(mode: mode);
  }

  /// Waits for the initial load, then runs [task] after any earlier write.
  Future<void> _write(Future<void> Function(IVaultRepository repo) task) {
    return _writes.run(() async {
      final repo = _repository;
      if (repo == null) {
        throw StateError('Local storage is not ready yet.');
      }
      await _initialLoad;
      await task(repo);
    });
  }

  Future<void> _mutateCards(
    List<VaultCardModel> Function(List<VaultCardModel> current) change,
  ) {
    return _write((repo) async {
      final updated = change(await repo.getCards());
      await repo.saveCards(updated);
      state = state.copyWith(cards: updated);
    });
  }

  Future<void> _mutateNotes(
    List<VaultNoteModel> Function(List<VaultNoteModel> current) change,
  ) {
    return _write((repo) async {
      final updated = change(await repo.getNotes());
      await repo.saveNotes(updated);
      state = state.copyWith(notes: updated);
    });
  }

  Future<void> deleteCard(String id) {
    return _mutateCards((current) => current.where((c) => c.id != id).toList());
  }

  Future<void> deleteNote(String id) {
    return _mutateNotes((current) => current.where((n) => n.id != id).toList());
  }

  Future<void> addCard(VaultCardModel card) {
    return _mutateCards((current) => [...current, card]);
  }

  Future<void> updateCard(VaultCardModel card) {
    return _mutateCards(
      (current) => current.map((c) => c.id == card.id ? card : c).toList(),
    );
  }

  Future<void> addNote(VaultNoteModel note) {
    return _mutateNotes((current) => [...current, note]);
  }

  Future<void> updateNote(VaultNoteModel note) {
    return _mutateNotes(
      (current) => current.map((n) => n.id == note.id ? note : n).toList(),
    );
  }
}
