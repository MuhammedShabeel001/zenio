import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/home.dart';
import 'package:zenio/features/wallet/domain/wallet_balances.dart';
import 'package:zenio/shared/providers/clock_provider/clock_provider.dart';
import 'package:zenio/shared/utils/datetime.dart';

part 'home_notifier.freezed.dart';
part 'home_notifier.g.dart';
part 'home_state.dart';

/// Owns the in-memory list of transactions. It is kept alive so that the list
/// survives tab switches; recreating it mid-session used to hand mutations an
/// empty, not-yet-loaded list.
@Riverpod(keepAlive: true)
class HomeNotifier extends _$HomeNotifier {
  IMoneyTrackerRepository? _moneyTrackerRepository;
  Future<void>? _initialLoad;

  /// The calendar month the summary was last worked out for.
  DateTime? _summaryMonth;

  @override
  HomeState build() {
    try {
      _moneyTrackerRepository = ref.watch(moneyTrackerRepositoryRepoProvider);
      _initialLoad = Future.microtask(loadMoneyTrackerData);
    } catch (_) {
      // Local storage is still opening; this notifier rebuilds once it is.
      _moneyTrackerRepository = null;
      _initialLoad = null;
    }

    return HomeState.initial();
  }

  Future<void> loadMoneyTrackerData() async {
    final repository = _moneyTrackerRepository;
    if (repository == null) return;
    state = state.copyWith(status: HomeStatus.loading);
    try {
      final transactions = await repository.getTransactions();
      state = state.copyWith(
        status: HomeStatus.success,
        transactions: transactions,
      );
      _recalculateSummary(transactions);
    } catch (e) {
      state = state.copyWith(status: HomeStatus.error);
    }
  }

  /// Waits until the stored transactions are in memory, so that a mutation
  /// never works from a partial list. Throws if they cannot be loaded.
  Future<IMoneyTrackerRepository> _readyRepository() async {
    final repository = _moneyTrackerRepository;
    if (repository == null) {
      throw StateError('Local storage is not ready yet.');
    }
    await _initialLoad;
    if (state.status != HomeStatus.success) {
      await loadMoneyTrackerData();
      if (state.status != HomeStatus.success) {
        throw StateError('Transactions could not be loaded.');
      }
    }
    return repository;
  }

  /// The stored transactions, once loaded. Throws if they cannot be loaded.
  Future<List<TransactionModel>> loadedTransactions() async {
    await _readyRepository();
    return state.transactions;
  }

  /// Moves every transaction of wallet [oldName] to [newName].
  Future<void> renameWallet(String oldName, String newName) async {
    final repository = await _readyRepository();
    await repository.renameWallet(oldName, newName);

    // The same change the repository made, applied to the loaded list
    // rather than reloading it: a failed reload would leave the old names
    // in memory and the wallets would work out their balances from them.
    state = state.copyWith(
      transactions: withWalletRenamed(state.transactions, oldName, newName),
    );
  }

  Future<void> addTransaction(TransactionModel newTx) async {
    final repository = await _readyRepository();
    await repository.insertTransaction(newTx);

    final updatedTxs = _newestFirst([newTx, ...state.transactions]);
    state = state.copyWith(transactions: updatedTxs);
    _recalculateSummary(updatedTxs);
  }

  Future<void> updateTransaction(TransactionModel updatedTx) async {
    final repository = await _readyRepository();
    await repository.updateTransaction(updatedTx);

    final updatedTxs = _newestFirst(
      state.transactions
          .map((tx) => tx.id == updatedTx.id ? updatedTx : tx)
          .toList(),
    );
    state = state.copyWith(transactions: updatedTxs);
    _recalculateSummary(updatedTxs);
  }

  Future<void> deleteTransaction(String id) async {
    final repository = await _readyRepository();
    await repository.deleteTransaction(id);

    final updatedTxs = state.transactions.where((tx) => tx.id != id).toList();
    if (updatedTxs.length == state.transactions.length) return;
    state = state.copyWith(transactions: updatedTxs);
    _recalculateSummary(updatedTxs);
  }

  /// Works out the month summary again if the calendar month has changed
  /// since it was last worked out, for example when Zenio comes back on the
  /// 1st after being left open. Transactions are neither reloaded nor
  /// changed. Returns whether the summary was worked out again.
  bool refreshForCurrentMonth() {
    final summaryMonth = _summaryMonth;
    if (state.status != HomeStatus.success || summaryMonth == null) {
      return false;
    }
    if (_monthOf(ref.read(clockProvider)()) == summaryMonth) return false;
    _recalculateSummary(state.transactions);
    return true;
  }

  static DateTime _monthOf(DateTime time) => DateTime(time.year, time.month);

  /// The order the database returns: by timestamp, then date, newest first,
  /// so a restored or re-dated transaction appears where a reload puts it.
  static List<TransactionModel> _newestFirst(List<TransactionModel> txs) {
    int byNewest(String? a, String? b) {
      if (a == b) return 0;
      if (a == null) return 1; // SQLite sorts NULL last when descending.
      if (b == null) return -1;
      return b.compareTo(a);
    }

    return txs
      ..sort(
        (a, b) {
          final byTimestamp = byNewest(a.timestamp, b.timestamp);
          if (byTimestamp != 0) return byTimestamp;
          final byDate = byNewest(a.date, b.date);
          return byDate != 0 ? byDate : b.id.compareTo(a.id);
        },
      );
  }

  void _recalculateSummary(List<TransactionModel> txs) {
    final now = ref.read(clockProvider)();
    final currentMonth = _monthOf(now);
    final previousMonth = DateTime(now.year, now.month - 1);
    _summaryMonth = currentMonth;

    double thisMonthIncome = 0;
    double thisMonthExpense = 0;
    double lastMonthIncome = 0;
    double lastMonthExpense = 0;
    double totalBalance = 0;

    for (final tx in txs) {
      // Transfers and balance adjustments are neither income nor spending.
      if (!tx.countsAsIncomeOrExpense) continue;

      if (tx.isIncome) {
        totalBalance += tx.amount;
      } else {
        totalBalance -= tx.amount;
      }

      final txDate = DateTimeUtils.parseTransactionDate(tx.date);
      if (txDate == null) continue;

      if (txDate.year == currentMonth.year &&
          txDate.month == currentMonth.month) {
        if (tx.isIncome) {
          thisMonthIncome += tx.amount;
        } else {
          thisMonthExpense += tx.amount;
        }
      } else if (txDate.year == previousMonth.year &&
          txDate.month == previousMonth.month) {
        if (tx.isIncome) {
          lastMonthIncome += tx.amount;
        } else {
          lastMonthExpense += tx.amount;
        }
      }
    }

    // Without last month's figure there is nothing to compare with; a
    // made-up +100% would be misleading.
    double? changeFrom(double last, double current) =>
        last > 0 ? (current - last) / last * 100 : null;
    final incomeChange = changeFrom(lastMonthIncome, thisMonthIncome);
    final expenseChange = changeFrom(lastMonthExpense, thisMonthExpense);

    final newSummary = FinancialSummaryModel(
      totalBalance: totalBalance,
      income: thisMonthIncome,
      incomeChangePercentage: incomeChange,
      expense: thisMonthExpense,
      expenseChangePercentage: expenseChange,
      selectedCurrency: state.summary?.selectedCurrency ?? 'INR',
    );

    state = state.copyWith(summary: newSummary);
  }
}
