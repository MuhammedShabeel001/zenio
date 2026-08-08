import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/home.dart';

part 'home_notifier.freezed.dart';
part 'home_notifier.g.dart';
part 'home_state.dart';

@Riverpod()
class HomeNotifier extends _$HomeNotifier {
  late TaskRepository taskRepository;
  IMoneyTrackerRepository? _moneyTrackerRepository;

  @override
  HomeState build() {
    taskRepository = ref.watch(taskRepositoryRepoProvider);

    try {
      _moneyTrackerRepository = ref.watch(moneyTrackerRepositoryRepoProvider);
      Future.microtask(loadMoneyTrackerData);
    } catch (_) {
      // Handles async initialization of SharedPreferences
    }

    return HomeState.initial();
  }

  Future<void> loadMoneyTrackerData() async {
    if (_moneyTrackerRepository == null) return;
    state = state.copyWith(status: HomeStatus.loading);
    try {
      final summary = await _moneyTrackerRepository!.getSummary();
      final transactions = await _moneyTrackerRepository!.getTransactions();
      state = state.copyWith(
        status: HomeStatus.success,
        summary: summary,
        transactions: transactions,
      );
    } catch (e) {
      state = state.copyWith(status: HomeStatus.error);
    }
  }

  Future<void> addTransaction(TransactionModel newTx) async {
    if (_moneyTrackerRepository == null) return;
    final updatedTxs = [newTx, ...state.transactions];
    await _moneyTrackerRepository!.saveTransactions(updatedTxs);

    final currentSummary = state.summary;
    if (currentSummary != null) {
      final newBalance = newTx.isIncome
          ? currentSummary.totalBalance + newTx.amount
          : currentSummary.totalBalance - newTx.amount;
      final newIncome = newTx.isIncome
          ? currentSummary.income + newTx.amount
          : currentSummary.income;
      final newExpense = !newTx.isIncome
          ? currentSummary.expense + newTx.amount
          : currentSummary.expense;

      final updatedSummary = currentSummary.copyWith(
        totalBalance: newBalance,
        income: newIncome,
        expense: newExpense,
      );

      await _moneyTrackerRepository!.saveSummary(updatedSummary);
      state = state.copyWith(
        summary: updatedSummary,
        transactions: updatedTxs,
      );
    } else {
      state = state.copyWith(transactions: updatedTxs);
    }
  }

  Future<void> getTasks() async {
    final tasks = await taskRepository.getTasks();
    state = state.copyWith(tasks: tasks);
  }
}
