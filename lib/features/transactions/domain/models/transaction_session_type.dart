import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_session_type.g.dart';

@JsonEnum(alwaysCreate: true)
enum TransactionSessionType {
  @JsonValue('expense')
  expense,
  @JsonValue('income')
  income,
  @JsonValue('transfer')
  transfer,
}

