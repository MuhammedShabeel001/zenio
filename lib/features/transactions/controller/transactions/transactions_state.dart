import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/domain/repositories/implementations/transactions_repository.dart';

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
      totalBalance: 2678.01,
      transactions: defaultTransactionsList,
      selectedPeriod: 'Monthly',
      selectedTimeframe: DateFormat('MMMM').format(DateTime.now()),
      isLoading: false,
    );
  }
}
