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
    required bool isIncome,
    required String currency,
  }) = _TransactionDetailModel;

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionDetailModelFromJson(json);
}
