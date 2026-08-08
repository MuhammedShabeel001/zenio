import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
sealed class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'date') required String date,
    @JsonKey(name: 'amount') required double amount,
    @JsonKey(name: 'currency') required String currency,
    @JsonKey(name: 'is_income') required bool isIncome,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
}
