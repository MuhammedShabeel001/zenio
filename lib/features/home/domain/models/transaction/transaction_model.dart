import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';

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
    @JsonKey(name: 'note') String? note,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'timestamp') String? timestamp,

    /// A [TransactionKind] name. Null for rows saved before kinds were
    /// stored; see [resolveTransactionKind].
    @JsonKey(name: 'kind') String? kind,

    /// The source and destination wallet of a transfer. Null for other
    /// transactions, and for transfers saved before they were stored, whose
    /// wallets are read from [bankName]; see [transferWallets].
    @JsonKey(name: 'transfer_from') String? transferFrom,
    @JsonKey(name: 'transfer_to') String? transferTo,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
}
