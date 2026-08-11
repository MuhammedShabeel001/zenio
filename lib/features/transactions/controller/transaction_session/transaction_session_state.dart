import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/transactions/domain/models/transaction_session_model.dart';

part 'transaction_session_state.freezed.dart';

@freezed
abstract class TransactionSessionState with _$TransactionSessionState {
  const factory TransactionSessionState({
    @Default([]) List<TransactionSessionModel> sessions,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _TransactionSessionState;

  factory TransactionSessionState.initial() => const TransactionSessionState(
        isLoading: true,
      );
}
