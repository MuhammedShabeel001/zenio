import 'package:freezed_annotation/freezed_annotation.dart';

part 'vault_note_model.freezed.dart';
part 'vault_note_model.g.dart';

@freezed
abstract class VaultNoteModel with _$VaultNoteModel {
  const factory VaultNoteModel({
    required String id,
    required String date,
    required String content,
  }) = _VaultNoteModel;

  factory VaultNoteModel.fromJson(Map<String, dynamic> json) =>
      _$VaultNoteModelFromJson(json);
}
