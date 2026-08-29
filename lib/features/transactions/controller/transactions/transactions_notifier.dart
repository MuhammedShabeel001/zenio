import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/transactions/controller/transactions/transactions_state.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/domain/repositories/implementations/transactions_repository.dart';

part 'transactions_notifier.g.dart';

@Riverpod(keepAlive: true)
class TransactionsNotifier extends _$TransactionsNotifier {
  @override
  TransactionsState build() {
    _loadData();
    return TransactionsState.initial();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(transactionsRepositoryRepoProvider);
      final balance = await repo.getTransactionsBalance();
      final list = await repo.getTransactions();
      state = state.copyWith(
        totalBalance: balance,
        transactions: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void updatePeriod(String period) {
    state = state.copyWith(selectedPeriod: period);
  }

  void updateTimeframe(String timeframe) {
    state = state.copyWith(selectedTimeframe: timeframe);
  }

  Future<void> deleteTransaction(String id) async {
    final target = state.transactions.firstWhere(
      (tx) => tx.id == id,
      orElse: () => const TransactionDetailModel(
        id: '',
        title: '',
        date: '',
        amount: 0,
        isIncome: false,
        currency: 'INR',
      ),
    );
    if (target.id.isEmpty) return;

    final updatedTxs = state.transactions.where((tx) => tx.id != id).toList();
    final repo = ref.read(transactionsRepositoryRepoProvider);
    await repo.saveTransactions(updatedTxs);

    final newBalance = target.isIncome
        ? state.totalBalance - target.amount
        : state.totalBalance + target.amount;

    state = state.copyWith(
      totalBalance: newBalance,
      transactions: updatedTxs,
    );
  }

  Future<void> addTransaction(TransactionDetailModel tx) async {
    final updatedTxs = [tx, ...state.transactions];
    final repo = ref.read(transactionsRepositoryRepoProvider);
    await repo.saveTransactions(updatedTxs);

    final newBalance = tx.isIncome
        ? state.totalBalance + tx.amount
        : state.totalBalance - tx.amount;

    await repo.saveTransactionsBalance(newBalance);

    state = state.copyWith(
      totalBalance: newBalance,
      transactions: updatedTxs,
    );
  }
}
