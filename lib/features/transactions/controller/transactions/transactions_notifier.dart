import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/transactions/controller/transactions/transactions_state.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/shared/utils/period_filter.dart';

part 'transactions_notifier.g.dart';

@Riverpod(keepAlive: true)
class TransactionsNotifier extends _$TransactionsNotifier {
  double _calculateTotalExpenses(List<TransactionDetailModel> txs) {
    double total = 0;
    for (final tx in txs) {
      if (tx.resolvedKind == TransactionKind.expense) {
        total += tx.amount;
      }
    }
    return total;
  }

  static List<TransactionDetailModel> _details(
    List<TransactionModel> transactions,
  ) {
    return [
      for (final t in transactions)
        TransactionDetailModel(
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
        ),
    ];
  }

  /// [base] showing the transactions of its period and timeframe.
  TransactionsState _filtered(
    TransactionsState base,
    List<TransactionModel> transactions,
  ) {
    final shown = filterByPeriod(
      _details(transactions),
      (tx) => tx.date,
      base.selectedPeriod,
      base.selectedTimeframe,
    );
    return base.copyWith(
      transactions: shown,
      totalBalance: _calculateTotalExpenses(shown),
    );
  }

  static bool _isLoading(HomeStatus status) =>
      status == HomeStatus.initial || status == HomeStatus.loading;

  @override
  TransactionsState build() {
    // Only the transactions and their loading state matter here, so a
    // summary update does not filter the whole list again.
    ref.listen(
      homeNotifierProvider.select(
        (s) => (status: s.status, transactions: s.transactions),
      ),
      (_, next) {
        switch (next.status) {
          case HomeStatus.initial:
          case HomeStatus.loading:
            state = state.copyWith(isLoading: true);
          case HomeStatus.error:
            // Stop the spinner; the screen offers a retry.
            state = state.copyWith(isLoading: false);
          case HomeStatus.success:
            state = _filtered(state, next.transactions).copyWith(
              isLoading: false,
            );
        }
      },
    );

    final home = ref.read(homeNotifierProvider);
    return _filtered(
      TransactionsState.initial().copyWith(
        isLoading: _isLoading(home.status),
      ),
      home.transactions,
    );
  }

  void updatePeriod(String period) {
    final defaultTimeframe = switch (period.toLowerCase()) {
      'daily' => 'Today',
      'weekly' => 'This week',
      'monthly' => DateFormat('MMMM').format(DateTime.now()),
      'custom' => allTimeTimeframe,
      _ => state.selectedTimeframe,
    };

    state = _filtered(
      state.copyWith(
        selectedPeriod: period,
        selectedTimeframe: defaultTimeframe,
      ),
      ref.read(homeNotifierProvider).transactions,
    );
  }

  void updateTimeframe(String timeframe) {
    state = _filtered(
      state.copyWith(selectedTimeframe: timeframe),
      ref.read(homeNotifierProvider).transactions,
    );
  }
}
