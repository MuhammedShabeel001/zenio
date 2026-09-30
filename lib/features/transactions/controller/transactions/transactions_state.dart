import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';

part 'transactions_state.freezed.dart';

@freezed
abstract class TransactionsState with _$TransactionsState {
  const factory TransactionsState({
    required double totalBalance,
    required List<TransactionDetailModel> transactions,
    required String selectedPeriod,
    required String selectedTimeframe,
    required bool isLoading,
    String? errorMessage,
  }) = _TransactionsState;

  factory TransactionsState.initial() {
    return TransactionsState(
      totalBalance: 0,
      transactions: const [],
      selectedPeriod: 'Monthly',
      selectedTimeframe: DateFormat('MMMM').format(DateTime.now()),
      isLoading: false,
    );
  }
}
