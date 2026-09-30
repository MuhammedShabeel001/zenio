import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/shared/utils/period_filter.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
// import 'package:zenio/features/home/controller/home/home_state.dart';
import 'package:zenio/features/transactions/controller/transactions/transactions_state.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';

part 'transactions_notifier.g.dart';

@Riverpod(keepAlive: true)
class TransactionsNotifier extends _$TransactionsNotifier {
  List<TransactionDetailModel> _filterTransactions(
    List<TransactionDetailModel> allTransactions,
    String period,
    String timeframe,
  ) {
    return filterByPeriod(allTransactions, (tx) => tx.date, period, timeframe);
  }

  double _calculateTotalExpenses(List<TransactionDetailModel> txs) {
    double total = 0;
    for (final tx in txs) {
      if (tx.resolvedKind == TransactionKind.expense) {
        total += tx.amount;
      }
    }
    return total;
  }

  @override
  TransactionsState build() {
    ref.listen(homeNotifierProvider, (previous, next) {
      if (next.status == HomeStatus.error) {
        // Stop the spinner; the screen offers a retry.
        state = state.copyWith(isLoading: false);
        return;
      }
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
              kind: t.kind,
            ),).toList();
        
        final filteredList = _filterTransactions(list, state.selectedPeriod, state.selectedTimeframe);
        final filteredBalance = _calculateTotalExpenses(filteredList);

        state = state.copyWith(
          totalBalance: filteredBalance,
          transactions: filteredList,
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
              kind: t.kind,
        ),).toList();

    const initialPeriod = 'Monthly';
    final initialTimeframe = DateFormat('MMMM').format(DateTime.now());
    final filteredList = _filterTransactions(list, initialPeriod, initialTimeframe);
    final filteredBalance = _calculateTotalExpenses(filteredList);

    return TransactionsState(
      totalBalance: filteredBalance,
      transactions: filteredList,
      isLoading: homeState.status == HomeStatus.loading,
      selectedPeriod: initialPeriod,
      selectedTimeframe: initialTimeframe,
    );
  }

  void updatePeriod(String period) {
    String defaultTimeframe = state.selectedTimeframe;
    switch (period.toLowerCase()) {
      case 'daily':
        defaultTimeframe = 'Today';
        break;
      case 'weekly':
        defaultTimeframe = 'This week';
        break;
      case 'monthly':
        final currentMonth = DateFormat('MMMM').format(DateTime.now());
        defaultTimeframe = currentMonth;
        break;
      case 'custom':
        defaultTimeframe = allTimeTimeframe;
        break;
    }
    
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
              kind: t.kind,
        ),).toList();
        
    final filteredList = _filterTransactions(list, period, defaultTimeframe);
    final filteredBalance = _calculateTotalExpenses(filteredList);
    
    state = state.copyWith(
      selectedPeriod: period, 
      selectedTimeframe: defaultTimeframe,
      transactions: filteredList,
      totalBalance: filteredBalance,
    );
  }

  void updateTimeframe(String timeframe) {
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
              kind: t.kind,
        ),).toList();
        
    final filteredList = _filterTransactions(list, state.selectedPeriod, timeframe);
    final filteredBalance = _calculateTotalExpenses(filteredList);

    state = state.copyWith(
      selectedTimeframe: timeframe,
      transactions: filteredList,
      totalBalance: filteredBalance,
    );
  }
}
