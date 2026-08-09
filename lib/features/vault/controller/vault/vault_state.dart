import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';
import 'package:zenio/features/vault/domain/repositories/implementations/vault_repository.dart';

part 'vault_state.freezed.dart';

enum VaultMode { cards, notes }

@freezed
abstract class VaultState with _$VaultState {
  const factory VaultState({
    required VaultMode mode,
    required List<VaultCardModel> cards,
    required List<VaultNoteModel> notes,
    required bool isLoading,
    String? errorMessage,
  }) = _VaultState;

  factory VaultState.initial() => const VaultState(
        mode: VaultMode.cards,
        cards: defaultVaultCards,
        notes: defaultVaultNotes,
        isLoading: false,
      );
}
