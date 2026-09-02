import 'package:freezed_annotation/freezed_annotation.dart';

part 'debt_model.freezed.dart';
part 'debt_model.g.dart';

@freezed
abstract class DebtModel with _$DebtModel {
  const factory DebtModel({
    required String id,
    required String personName,
    required String date,
    required double amount,
    required String currency,
    required bool isOwed,
    required String iconName,
    String? note,
  }) = _DebtModel;

  factory DebtModel.fromJson(Map<String, dynamic> json) =>
      _$DebtModelFromJson(json);
}
