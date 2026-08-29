import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
// import 'package:zenio/features/home/controller/home/home_state.dart';
import 'package:zenio/features/transactions/controller/transactions/transactions_state.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/domain/repositories/implementations/transactions_repository.dart';

part 'transactions_notifier.g.dart';

@Riverpod(keepAlive: true)
class TransactionsNotifier extends _$TransactionsNotifier {
  @override
  TransactionsState build() {
    ref.listen(homeNotifierProvider, (previous, next) {
      if (next.status == HomeStatus.success) {
        final list = next.transactions.map((t) => TransactionDetailModel(
          id: t.id,
          title: t.title,
          date: t.date,
          amount: t.amount,
          isIncome: t.isIncome,
          currency: t.currency,
          note: t.note,
          bankName: t.bankName,
          timestamp: t.timestamp,
        )).toList();
        state = state.copyWith(
          totalBalance: next.summary?.totalBalance ?? 23678.01,
          transactions: list,
          isLoading: false,
        );
      }
    });

    final homeState = ref.read(homeNotifierProvider);
    final list = homeState.transactions.map((t) => TransactionDetailModel(
      id: t.id,
      title: t.title,
      date: t.date,
      amount: t.amount,
      isIncome: t.isIncome,
      currency: t.currency,
      note: t.note,
      bankName: t.bankName,
      timestamp: t.timestamp,
    )).toList();

    return TransactionsState(
      totalBalance: homeState.summary?.totalBalance ?? 23678.01,
      transactions: list,
      isLoading: homeState.status == HomeStatus.loading,
      selectedPeriod: 'This week',
      selectedTimeframe: 'Month',
    );
  }

  void updatePeriod(String period) {
    state = state.copyWith(selectedPeriod: period);
  }

  void updateTimeframe(String timeframe) {
    state = state.copyWith(selectedTimeframe: timeframe);
  }

  Future<void> deleteTransaction(String id) async {
    await ref.read(homeNotifierProvider.notifier).deleteTransaction(id);
  }

  Future<void> addTransaction(TransactionDetailModel tx) async {
    // Only required because AddTransactionBottomSheet uses both providers temporarily
    // but in reality we only need to call homeNotifierProvider.
    // For safety against double-saving, we will rely on homeNotifierProvider directly.
  }
}
