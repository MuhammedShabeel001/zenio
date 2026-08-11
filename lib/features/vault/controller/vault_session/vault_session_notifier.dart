import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/vault/controller/vault_session/vault_session_state.dart';
import 'package:zenio/features/vault/domain/models/vault_card_session_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_session_model.dart';
import 'package:zenio/features/vault/domain/repositories/implementations/vault_session_repository.dart';

part 'vault_session_notifier.g.dart';

@Riverpod(keepAlive: true)
class VaultSessionNotifier extends _$VaultSessionNotifier {
  @override
  VaultSessionState build() {
    _loadVaultData();
    return VaultSessionState.initial();
  }

  Future<void> _loadVaultData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(vaultSessionRepositoryRepoProvider);
      final cardsList = await repo.getVaultCardSessions();
      final notesList = await repo.getVaultNoteSessions();
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

  // Vault Card Sessions
  Future<void> addVaultCardSession(VaultCardSessionModel card) async {
    try {
      final repo = ref.read(vaultSessionRepositoryRepoProvider);
      await repo.saveVaultCardSession(card);
      await _loadVaultData();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateVaultCardSession(VaultCardSessionModel card) async {
    try {
      final repo = ref.read(vaultSessionRepositoryRepoProvider);
      await repo.updateVaultCardSession(card);
      await _loadVaultData();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteVaultCardSession(String id) async {
    try {
      final repo = ref.read(vaultSessionRepositoryRepoProvider);
      await repo.deleteVaultCardSession(id);
      await _loadVaultData();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // Vault Note Sessions
  Future<void> addVaultNoteSession(VaultNoteSessionModel note) async {
    try {
      final repo = ref.read(vaultSessionRepositoryRepoProvider);
      await repo.saveVaultNoteSession(note);
      await _loadVaultData();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateVaultNoteSession(VaultNoteSessionModel note) async {
    try {
      final repo = ref.read(vaultSessionRepositoryRepoProvider);
      await repo.updateVaultNoteSession(note);
      await _loadVaultData();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteVaultNoteSession(String id) async {
    try {
      final repo = ref.read(vaultSessionRepositoryRepoProvider);
      await repo.deleteVaultNoteSession(id);
      await _loadVaultData();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> clearAllVaultData() async {
    try {
      final repo = ref.read(vaultSessionRepositoryRepoProvider);
      await repo.clearAllVaultCardSessions();
      await repo.clearAllVaultNoteSessions();
      await _loadVaultData();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}
