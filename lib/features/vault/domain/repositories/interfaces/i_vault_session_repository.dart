import 'package:zenio/features/vault/domain/models/vault_card_session_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_session_model.dart';

abstract class IVaultSessionRepository {
  // Vault Card Sessions
  Future<List<VaultCardSessionModel>> getVaultCardSessions();
  Future<VaultCardSessionModel?> getVaultCardSessionById(String id);
  Future<void> saveVaultCardSession(VaultCardSessionModel card);
  Future<void> updateVaultCardSession(VaultCardSessionModel card);
  Future<void> deleteVaultCardSession(String id);
  Future<void> clearAllVaultCardSessions();

  // Vault Note Sessions
  Future<List<VaultNoteSessionModel>> getVaultNoteSessions();
  Future<VaultNoteSessionModel?> getVaultNoteSessionById(String id);
  Future<void> saveVaultNoteSession(VaultNoteSessionModel note);
  Future<void> updateVaultNoteSession(VaultNoteSessionModel note);
  Future<void> deleteVaultNoteSession(String id);
  Future<void> clearAllVaultNoteSessions();
}
