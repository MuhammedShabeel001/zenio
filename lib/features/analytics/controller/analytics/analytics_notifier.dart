import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';

part 'analytics_notifier.freezed.dart';
part 'analytics_notifier.g.dart';
part 'analytics_state.dart';

@Riverpod()
class AnalyticsNotifier extends _$AnalyticsNotifier {
  List<TransactionModel> _filterTransactions(
    List<TransactionModel> allTransactions,
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
      final int currentDay = now.weekday;
      final DateTime startOfWeek = now.subtract(Duration(days: currentDay - 1));
      final DateTime startOfPastWeek = startOfWeek.subtract(const Duration(days: 7));
      final DateTime endOfPastWeek = startOfWeek.subtract(const Duration(days: 1));

      return allTransactions.where((tx) {
        try {
          final txDate = DateFormat('dd-MM-yyyy').parse(tx.date);
          if (timeframe.toLowerCase() == 'this week') {
            return txDate.isAfter(startOfWeek.subtract(const Duration(days: 1)));
          } else if (timeframe.toLowerCase() == 'last week') {
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
    }
    return allTransactions;
  }

  (double, List<CategorySpendModel>) _computeAnalytics(List<TransactionModel> txs) {
    double totalExpense = 0;
    final Map<String, List<TransactionModel>> categorized = {};

    for (final tx in txs) {
      if (tx.isIncome || tx.title.startsWith('Transfer to')) continue;
      
      totalExpense += tx.amount;
      final category = tx.title;
      categorized.putIfAbsent(category, () => []).add(tx);
    }

    final List<CategorySpendModel> spends = [];
    int idCounter = 1;

    for (final entry in categorized.entries) {
      final categoryName = entry.key;
      final categoryTxs = entry.value;
      
      final amount = categoryTxs.fold(0.0, (sum, tx) => sum + tx.amount);
      
      String colorHex = '0xFF1DA1F2';
      String iconName = 'expense';

      final nameLower = categoryName.toLowerCase();
      if (nameLower.contains('travel')) {
        colorHex = '0xFFFF771C';
        iconName = 'travel';
      } else if (nameLower.contains('entertainment')) {
        colorHex = '0xFF8C43E6';
        iconName = 'entertainment';
      } else if (nameLower.contains('loan') || nameLower.contains('debt')) {
        colorHex = '0xFF10B981';
        iconName = 'debt';
      } else if (nameLower.contains('food') || nameLower.contains('drink')) {
        colorHex = '0xFFFF4D4D';
        iconName = 'expense';
      } else if (nameLower.contains('shopping')) {
        colorHex = '0xFF1DA1F2';
        iconName = 'card';
      } else if (nameLower.contains('grocery')) {
        colorHex = '0xFF00C4DE';
        iconName = 'wallet';
      } else {
        // Fallback random colors for unknown categories based on name length
        final colors = ['0xFFFF771C', '0xFF8C43E6', '0xFF10B981', '0xFFFF4D4D', '0xFF1DA1F2', '0xFF00C4DE'];
        colorHex = colors[categoryName.length % colors.length];
      }

      spends.add(CategorySpendModel(
        id: idCounter.toString(),
        name: categoryName,
        amount: amount,
        spendsCount: categoryTxs.length,
        colorHex: colorHex,
        iconName: iconName,
      ));
      idCounter++;
    }

    spends.sort((a, b) => b.amount.compareTo(a.amount));

    return (totalExpense, spends);
  }

  @override
  AnalyticsState build() {
    ref.listen(homeNotifierProvider, (previous, next) {
      if (next.status == HomeStatus.success) {
        final filteredList = _filterTransactions(next.transactions, state.selectedPeriod, state.selectedTimeframe);
        final (balance, spends) = _computeAnalytics(filteredList);

        state = state.copyWith(
          status: AnalyticsStatus.success,
          totalBalance: balance,
          categorySpends: spends,
        );
      }
    });

    final homeState = ref.read(homeNotifierProvider);
    
    final currentMonth = DateFormat('MMMM').format(DateTime.now());
    const initialPeriod = 'Monthly';
    final initialTimeframe = currentMonth;
    
    final filteredList = _filterTransactions(homeState.transactions, initialPeriod, initialTimeframe);
    final (balance, spends) = _computeAnalytics(filteredList);

    return AnalyticsState(
      status: homeState.status == HomeStatus.loading ? AnalyticsStatus.loading : AnalyticsStatus.success,
      totalBalance: balance,
      categorySpends: spends,
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
    final filteredList = _filterTransactions(homeState.transactions, period, defaultTimeframe);
    final (balance, spends) = _computeAnalytics(filteredList);
    
    state = state.copyWith(
      selectedPeriod: period, 
      selectedTimeframe: defaultTimeframe,
      totalBalance: balance,
      categorySpends: spends,
    );
  }

  void updateTimeframe(String timeframe) {
    final homeState = ref.read(homeNotifierProvider);
    final filteredList = _filterTransactions(homeState.transactions, state.selectedPeriod, timeframe);
    final (balance, spends) = _computeAnalytics(filteredList);

    state = state.copyWith(
      selectedTimeframe: timeframe,
      totalBalance: balance,
      categorySpends: spends,
    );
  }
}
