import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/vault/domain/models/vault_card_session_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_session_model.dart';

part 'vault_session_state.freezed.dart';

@freezed
abstract class VaultSessionState with _$VaultSessionState {
  const factory VaultSessionState({
    @Default([]) List<VaultCardSessionModel> cards,
    @Default([]) List<VaultNoteSessionModel> notes,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _VaultSessionState;

  factory VaultSessionState.initial() => const VaultSessionState(
        isLoading: true,
      );
}
