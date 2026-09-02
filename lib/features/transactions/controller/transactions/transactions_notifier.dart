import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
// import 'package:zenio/features/home/controller/home/home_state.dart';
import 'package:zenio/features/transactions/controller/transactions/transactions_state.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/domain/repositories/implementations/transactions_repository.dart';

part 'transactions_notifier.g.dart';

@Riverpod(keepAlive: true)
class TransactionsNotifier extends _$TransactionsNotifier {
  List<TransactionDetailModel> _filterTransactions(
    List<TransactionDetailModel> allTransactions,
    String period,
    String timeframe,
  ) {
    if (period.toLowerCase() == 'daily') {
      final now = DateTime.now();
      DateTime targetDate;
      if (timeframe.toLowerCase() == 'today') {
        targetDate = now;
      } else if (timeframe.toLowerCase() == 'yesterday') {
        targetDate = now.subtract(const Duration(days: 1));
      } else {
        return allTransactions;
      }

      return allTransactions.where((tx) {
        try {
          final txDate = DateFormat('dd-MM-yyyy').parse(tx.date);
          return txDate.year == targetDate.year &&
              txDate.month == targetDate.month &&
              txDate.day == targetDate.day;
        } catch (_) {
          return false;
        }
      }).toList();
    } else if (period.toLowerCase() == 'weekly') {
      final now = DateTime.now();
      final int currentDay = now.weekday; // 1 = Monday, 7 = Sunday
      final DateTime startOfWeek = now.subtract(Duration(days: currentDay - 1));
      final DateTime startOfPastWeek = startOfWeek.subtract(const Duration(days: 7));
      final DateTime endOfPastWeek = startOfWeek.subtract(const Duration(days: 1));

      return allTransactions.where((tx) {
        try {
          final txDate = DateFormat('dd-MM-yyyy').parse(tx.date);
          if (timeframe.toLowerCase() == 'this week') {
            return txDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
          } else if (timeframe.toLowerCase() == 'past week') {
            return txDate.isAfter(startOfPastWeek.subtract(const Duration(days: 1))) &&
                txDate.isBefore(endOfPastWeek.add(const Duration(days: 1)));
          }
          return true;
        } catch (_) {
          return false;
        }
      }).toList();
    } else if (period.toLowerCase() == 'monthly') {
      final int monthIndex = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ].indexWhere((m) => m.toLowerCase() == timeframe.toLowerCase());

      if (monthIndex == -1) return allTransactions;

      final targetMonth = monthIndex + 1;
      return allTransactions.where((tx) {
        try {
          final txDate = DateFormat('dd-MM-yyyy').parse(tx.date);
          return txDate.month == targetMonth && txDate.year == DateTime.now().year;
        } catch (_) {
          return false;
        }
      }).toList();
    } else if (period.toLowerCase() == 'custom') {
      if (timeframe.contains(' - ')) {
        final parts = timeframe.split(' - ');
        if (parts.length == 2) {
          try {
            final now = DateTime.now();
            var start = DateFormat('dd MMM').parse(parts[0]);
            var end = DateFormat('dd MMM').parse(parts[1]);
            start = DateTime(now.year, start.month, start.day);
            end = DateTime(now.year, end.month, end.day, 23, 59, 59);

            return allTransactions.where((tx) {
              try {
                final txDate = DateFormat('dd-MM-yyyy').parse(tx.date);
                return txDate.isAfter(start.subtract(const Duration(days: 1))) &&
                    txDate.isBefore(end.add(const Duration(days: 1)));
              } catch (_) {
                return false;
              }
            }).toList();
          } catch (_) {
            return allTransactions;
          }
        }
      }
      return allTransactions;
    }

    return allTransactions;
  }

  double _calculateTotalBalance(List<TransactionDetailModel> txs) {
    double total = 0;
    for (final tx in txs) {
      final isTransfer = tx.title.startsWith('Transfer to');
      if (isTransfer) continue;

      if (tx.isIncome) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

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
        
        final filteredList = _filterTransactions(list, state.selectedPeriod, state.selectedTimeframe);
        final filteredBalance = _calculateTotalBalance(filteredList);

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
        )).toList();

    const initialPeriod = 'Monthly';
    final initialTimeframe = DateFormat('MMMM').format(DateTime.now());
    final filteredList = _filterTransactions(list, initialPeriod, initialTimeframe);
    final filteredBalance = _calculateTotalBalance(filteredList);

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
        defaultTimeframe = 'Select Range';
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
        )).toList();
        
    final filteredList = _filterTransactions(list, period, defaultTimeframe);
    final filteredBalance = _calculateTotalBalance(filteredList);
    
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
        )).toList();
        
    final filteredList = _filterTransactions(list, state.selectedPeriod, timeframe);
    final filteredBalance = _calculateTotalBalance(filteredList);

    state = state.copyWith(
      selectedTimeframe: timeframe,
      transactions: filteredList,
      totalBalance: filteredBalance,
    );
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
