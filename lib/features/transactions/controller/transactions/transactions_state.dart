import 'package:freezed_annotation/freezed_annotation.dart';
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

  factory TransactionsState.initial() => const TransactionsState(
        totalBalance: 2678.01,
        transactions: [],
        selectedPeriod: 'Week',
        selectedTimeframe: 'This Week',
        isLoading: false,
      );
}
