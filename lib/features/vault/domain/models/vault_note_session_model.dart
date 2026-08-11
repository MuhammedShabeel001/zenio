import 'package:freezed_annotation/freezed_annotation.dart';

part 'vault_note_session_model.freezed.dart';
part 'vault_note_session_model.g.dart';

@freezed
abstract class VaultNoteSessionModel with _$VaultNoteSessionModel {
  const factory VaultNoteSessionModel({
    required String id,
    required String title,
    required String description,
  }) = _VaultNoteSessionModel;

  factory VaultNoteSessionModel.fromJson(Map<String, dynamic> json) =>
      _$VaultNoteSessionModelFromJson(json);
}
