import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_detail_model.freezed.dart';
part 'transaction_detail_model.g.dart';

@freezed
abstract class TransactionDetailModel with _$TransactionDetailModel {
  const factory TransactionDetailModel({
    required String id,
    required String title,
    required String date,
    required double amount,
    @JsonKey(name: 'is_income') required bool isIncome,
    @JsonKey(name: 'currency') required String currency,
    @JsonKey(name: 'note') String? note,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'timestamp') String? timestamp,
  }) = _TransactionDetailModel;

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionDetailModelFromJson(json);
}
