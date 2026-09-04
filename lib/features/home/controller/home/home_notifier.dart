import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
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
      // Handles async initialization of SqlitePrefs
    }

    return HomeState.initial();
  }

  Future<void> loadMoneyTrackerData() async {
    if (_moneyTrackerRepository == null) return;
    state = state.copyWith(status: HomeStatus.loading);
    try {
      final transactions = await _moneyTrackerRepository!.getTransactions();
      state = state.copyWith(
        status: HomeStatus.success,
        transactions: transactions,
      );
      await _recalculateSummary(transactions);
    } catch (e) {
      state = state.copyWith(status: HomeStatus.error);
    }
  }

  Future<void> addTransaction(TransactionModel newTx) async {
    if (_moneyTrackerRepository == null) return;
    final updatedTxs = [newTx, ...state.transactions];
    await _moneyTrackerRepository!.saveTransactions(updatedTxs);

    state = state.copyWith(transactions: updatedTxs);
    await _recalculateSummary(updatedTxs);
  }

  Future<void> updateTransaction(TransactionModel updatedTx) async {
    if (_moneyTrackerRepository == null) return;
    final updatedTxs = state.transactions
        .map((tx) => tx.id == updatedTx.id ? updatedTx : tx)
        .toList();
    await _moneyTrackerRepository!.saveTransactions(updatedTxs);

    state = state.copyWith(transactions: updatedTxs);
    await _recalculateSummary(updatedTxs);
  }

  Future<void> deleteTransaction(String id) async {
    final target = state.transactions.firstWhere(
      (tx) => tx.id == id,
      orElse: () => const TransactionModel(
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
    if (_moneyTrackerRepository != null) {
      await _moneyTrackerRepository!.saveTransactions(updatedTxs);
    }

    state = state.copyWith(transactions: updatedTxs);
    await _recalculateSummary(updatedTxs);
  }

  Future<void> _recalculateSummary(List<TransactionModel> txs) async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final previousMonth = DateTime(now.year, now.month - 1);

    double thisMonthIncome = 0;
    double thisMonthExpense = 0;
    double lastMonthIncome = 0;
    double lastMonthExpense = 0;
    double totalBalance = 0;

    for (final tx in txs) {
      final isTransfer = tx.title.startsWith('Transfer to');
      if (isTransfer) continue;

      if (tx.isIncome) {
        totalBalance += tx.amount;
      } else {
        totalBalance -= tx.amount;
      }

      DateTime txDate;
      try {
        txDate = DateFormat('dd-MM-yyyy').parse(tx.date);
      } catch (_) {
        continue;
      }

      if (txDate.year == currentMonth.year && txDate.month == currentMonth.month) {
        if (tx.isIncome) {
          thisMonthIncome += tx.amount;
        } else {
          thisMonthExpense += tx.amount;
        }
      } else if (txDate.year == previousMonth.year && txDate.month == previousMonth.month) {
        if (tx.isIncome) {
          lastMonthIncome += tx.amount;
        } else {
          lastMonthExpense += tx.amount;
        }
      }
    }

    double incomeChange = 0;
    if (lastMonthIncome > 0) {
      incomeChange = ((thisMonthIncome - lastMonthIncome) / lastMonthIncome) * 100;
    } else if (thisMonthIncome > 0) {
      incomeChange = 100;
    }

    double expenseChange = 0;
    if (lastMonthExpense > 0) {
      expenseChange = ((thisMonthExpense - lastMonthExpense) / lastMonthExpense) * 100;
    } else if (thisMonthExpense > 0) {
      expenseChange = 100;
    }

    final newSummary = FinancialSummaryModel(
      totalBalance: totalBalance,
      income: thisMonthIncome,
      incomeChangePercentage: incomeChange,
      expense: thisMonthExpense,
      expenseChangePercentage: expenseChange,
      selectedCurrency: state.summary?.selectedCurrency ?? 'INR',
    );

    if (_moneyTrackerRepository != null) {
      await _moneyTrackerRepository!.saveSummary(newSummary);
    }

    state = state.copyWith(summary: newSummary);
  }

  Future<void> getTasks() async {
    final tasks = await taskRepository.getTasks();
    state = state.copyWith(tasks: tasks);
  }
}
