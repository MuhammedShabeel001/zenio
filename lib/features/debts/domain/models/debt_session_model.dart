import 'package:freezed_annotation/freezed_annotation.dart';

part 'debt_session_model.freezed.dart';
part 'debt_session_model.g.dart';

@freezed
abstract class DebtSessionModel with _$DebtSessionModel {
  const factory DebtSessionModel({
    required String id,
    required String personName,
    required double amount,
    String? dueDate,
    String? note,
    required String date,
  }) = _DebtSessionModel;

  factory DebtSessionModel.fromJson(Map<String, dynamic> json) =>
      _$DebtSessionModelFromJson(json);
}
