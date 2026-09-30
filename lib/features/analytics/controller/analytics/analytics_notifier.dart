import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/shared/utils/period_filter.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/subscriptions/controller/categories/subscription_categories_notifier.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';

part 'analytics_notifier.freezed.dart';
part 'analytics_notifier.g.dart';
part 'analytics_state.dart';

@Riverpod()
class AnalyticsNotifier extends _$AnalyticsNotifier {
  List<TransactionModel> _filterTransactions(
    List<TransactionModel> allTransactions,
    String period,
    String timeframe,
    String wallet,
  ) {
    var transactions = allTransactions;

    if (wallet.trim().toLowerCase() != 'all wallets' &&
        wallet.trim().toLowerCase() != 'all') {
      final targetWallet = wallet.trim().toLowerCase();
      transactions = transactions.where((tx) {
        final bName = tx.bankName?.trim().toLowerCase();
        if (bName == null) return false;
        return bName == targetWallet ||
            bName.startsWith('$targetWallet ->') ||
            bName.endsWith('-> $targetWallet');
      }).toList();
    }

    return filterByPeriod(transactions, (tx) => tx.date, period, timeframe);
  }

  (double, List<CategorySpendModel>) _computeAnalytics(List<TransactionModel> txs) {
    double totalExpense = 0;
    final Map<String, List<TransactionModel>> categorized = {};

    for (final tx in txs) {
      if (tx.resolvedKind != TransactionKind.expense) continue;
      
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

      final nameLower = categoryName.toLowerCase();
      if (nameLower.contains('travel')) {
        colorHex = '0xFFFF771C';
      } else if (nameLower.contains('entertainment')) {
        colorHex = '0xFF8C43E6';
      } else if (nameLower.contains('loan') || nameLower.contains('debt')) {
        colorHex = '0xFF10B981';
      } else if (nameLower.contains('food') || nameLower.contains('drink')) {
        colorHex = '0xFFFF4D4D';
      } else if (nameLower.contains('shopping')) {
        colorHex = '0xFF1DA1F2';
      } else if (nameLower.contains('grocery')) {
        colorHex = '0xFF00C4DE';
      } else {
        // Fallback random colors for unknown categories based on name length
        final colors = ['0xFFFF771C', '0xFF8C43E6', '0xFF10B981', '0xFFFF4D4D', '0xFF1DA1F2', '0xFF00C4DE'];
        colorHex = colors[categoryName.length % colors.length];
      }

      // Resolve category emoji from saved categories or intelligent fallback
      final categories = ref.read(categoriesNotifierProvider);
      final subCategories = ref.read(subscriptionCategoriesNotifierProvider);
      final cleanName = categoryName.trim().toLowerCase();

      String emoji = '';
      final exactMatch = categories.where(
        (c) => c.name.trim().toLowerCase() == cleanName,
      );
      if (exactMatch.isNotEmpty && exactMatch.first.emoji.trim().isNotEmpty) {
        emoji = exactMatch.first.emoji.trim();
      } else {
        final subMatch = subCategories.where(
          (c) => c.name.trim().toLowerCase() == cleanName,
        );
        if (subMatch.isNotEmpty && subMatch.first.emoji.trim().isNotEmpty) {
          emoji = subMatch.first.emoji.trim();
        } else {
          final fuzzyMatch = categories.where(
            (c) =>
                cleanName.contains(c.name.trim().toLowerCase()) ||
                c.name.trim().toLowerCase().contains(cleanName),
          );
          if (fuzzyMatch.isNotEmpty && fuzzyMatch.first.emoji.trim().isNotEmpty) {
            emoji = fuzzyMatch.first.emoji.trim();
          }
        }
      }

      if (emoji.isEmpty) {
        if (nameLower.contains('travel') || nameLower.contains('trip') || nameLower.contains('fuel')) {
          emoji = '🚗';
        } else if (nameLower.contains('food') || nameLower.contains('drink') || nameLower.contains('dine')) {
          emoji = '🍔';
        } else if (nameLower.contains('entertainment') || nameLower.contains('movie')) {
          emoji = '🎬';
        } else if (nameLower.contains('shopping') || nameLower.contains('shop')) {
          emoji = '🛍️';
        } else if (nameLower.contains('bills') || nameLower.contains('bill')) {
          emoji = '💡';
        } else if (nameLower.contains('loan') || nameLower.contains('debt')) {
          emoji = '💳';
        } else if (nameLower.contains('grocery')) {
          emoji = '🛒';
        } else if (nameLower.contains('health') || nameLower.contains('medical')) {
          emoji = '💊';
        } else {
          emoji = '🏷️';
        }
      }

      spends.add(CategorySpendModel(
        id: idCounter.toString(),
        name: categoryName,
        amount: amount,
        spendsCount: categoryTxs.length,
        colorHex: colorHex,
        iconName: emoji,
      ),);
      idCounter++;
    }

    spends.sort((a, b) => b.amount.compareTo(a.amount));

    return (totalExpense, spends);
  }

  @override
  AnalyticsState build() {
    // Only the transactions and their loading state matter here, so a
    // summary update does not work everything out again.
    ref.listen(
        homeNotifierProvider.select(
          (s) => (status: s.status, transactions: s.transactions),
        ), (previous, next) {
      if (next.status == HomeStatus.error) {
        state = state.copyWith(status: AnalyticsStatus.error);
        return;
      }
      if (next.status == HomeStatus.success) {
        final filteredList = _filterTransactions(
          next.transactions,
          state.selectedPeriod,
          state.selectedTimeframe,
          state.selectedWallet,
        );
        final (balance, spends) = _computeAnalytics(filteredList);

        state = state.copyWith(
          status: AnalyticsStatus.success,
          totalBalance: balance,
          categorySpends: spends,
        );
      }
    });

    ref.listen(categoriesNotifierProvider, (previous, next) {
      final homeState = ref.read(homeNotifierProvider);
      if (homeState.status == HomeStatus.success) {
        final filteredList = _filterTransactions(
          homeState.transactions,
          state.selectedPeriod,
          state.selectedTimeframe,
          state.selectedWallet,
        );
        final (balance, spends) = _computeAnalytics(filteredList);

        state = state.copyWith(
          categorySpends: spends,
        );
      }
    });

    ref.listen(walletNotifierProvider.select((s) => s.cards), (previous, cards) {
      if (state.selectedWallet != 'All Wallets' && state.selectedWallet != 'All') {
        final walletExists = cards.any(
          (c) => c.bankName.trim().toLowerCase() == state.selectedWallet.trim().toLowerCase(),
        );
        if (!walletExists) {
          updateWallet('All Wallets');
        }
      }
    });

    final homeState = ref.read(homeNotifierProvider);
    
    final currentMonth = DateFormat('MMMM').format(DateTime.now());
    const initialPeriod = 'Monthly';
    final initialTimeframe = currentMonth;
    const initialWallet = 'All Wallets';
    
    final filteredList = _filterTransactions(homeState.transactions, initialPeriod, initialTimeframe, initialWallet);
    final (balance, spends) = _computeAnalytics(filteredList);

    return AnalyticsState(
      status: switch (homeState.status) {
        HomeStatus.initial || HomeStatus.loading => AnalyticsStatus.loading,
        HomeStatus.error => AnalyticsStatus.error,
        HomeStatus.success => AnalyticsStatus.success,
      },
      totalBalance: balance,
      categorySpends: spends,
      selectedPeriod: initialPeriod,
      selectedTimeframe: initialTimeframe,
      selectedWallet: initialWallet,
    );
  }

  void updateWallet(String wallet) {
    final homeState = ref.read(homeNotifierProvider);
    final filteredList = _filterTransactions(
      homeState.transactions,
      state.selectedPeriod,
      state.selectedTimeframe,
      wallet,
    );
    final (balance, spends) = _computeAnalytics(filteredList);

    state = state.copyWith(
      selectedWallet: wallet,
      totalBalance: balance,
      categorySpends: spends,
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
    final filteredList = _filterTransactions(
      homeState.transactions,
      period,
      defaultTimeframe,
      state.selectedWallet,
    );
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
    final filteredList = _filterTransactions(
      homeState.transactions,
      state.selectedPeriod,
      timeframe,
      state.selectedWallet,
    );
    final (balance, spends) = _computeAnalytics(filteredList);

    state = state.copyWith(
      selectedTimeframe: timeframe,
      totalBalance: balance,
      categorySpends: spends,
    );
  }

  List<TransactionModel> filterTransactions(List<TransactionModel> allTransactions) {
    return _filterTransactions(
      allTransactions,
      state.selectedPeriod,
      state.selectedTimeframe,
      state.selectedWallet,
    );
  }
}
