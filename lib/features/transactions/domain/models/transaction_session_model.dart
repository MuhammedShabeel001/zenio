import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/transactions/domain/models/transaction_session_type.dart';

part 'transaction_session_model.freezed.dart';
part 'transaction_session_model.g.dart';

@freezed
abstract class TransactionSessionModel with _$TransactionSessionModel {
  const factory TransactionSessionModel({
    required String id,
    required TransactionSessionType type,
    required double amount,
    required String date,
    required String time,
    String? wallet,
    String? category,
    String? fromWallet,
    String? toWallet,
    String? note,
  }) = _TransactionSessionModel;

  factory TransactionSessionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionSessionModelFromJson(json);
}
