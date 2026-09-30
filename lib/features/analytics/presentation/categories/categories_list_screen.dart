import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/analytics/controller/analytics/analytics_notifier.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/features/analytics/domain/spending_breakdown.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/transactions/domain/models/category_item_model.dart';
import 'package:zenio/features/transactions/presentation/widgets/manage_categories_bottom_sheet.dart';
import 'package:zenio/shared/shared.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

enum CategorySortOption {
  highestSpend('Highest Spend'),
  mostSpends('Most Spends'),
  alphabetical('Name (A-Z)');

  const CategorySortOption(this.label);
  final String label;
}

enum CategoryFilterTab {
  all('All'),
  active('With Spends'),
  zero('Zero Spends');

  const CategoryFilterTab(this.label);
  final String label;
}

class CategoriesListScreen extends ConsumerStatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  ConsumerState<CategoriesListScreen> createState() =>
      _CategoriesListScreenState();
}

class _CategoriesListScreenState extends ConsumerState<CategoriesListScreen> {
  CategorySortOption _sortOption = CategorySortOption.highestSpend;
  CategoryFilterTab _activeTab = CategoryFilterTab.all;
  String? _expandedCategoryId;

  String _formatTxDate(String rawDate) {
    final parsed = DateTimeUtils.parseTransactionDate(rawDate);
    if (parsed == null) return rawDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final check = DateTime(parsed.year, parsed.month, parsed.day);
    if (check == today) return 'Today';
    if (check == yesterday) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(parsed);
  }

  Color _getBadgeBackgroundColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('travel')) return const Color(0xFFFDF3E7);
    if (lower.contains('entertainment')) return const Color(0xFFF4ECFB);
    if (lower.contains('loan') || lower.contains('debt')) {
      return const Color(0xFFE8F8F0);
    }
    if (lower.contains('food')) return const Color(0xFFFFEAEA);
    if (lower.contains('shop')) return const Color(0xFFE6F3FF);
    return const Color(0xFFF2F2F5);
  }

  Color _getCategoryColor(String name, String hex) {
    if (hex.isNotEmpty) {
      try {
        var clean = hex.replaceAll('#', '').trim();
        if (clean.startsWith('0x') || clean.startsWith('0X')) {
          return Color(int.parse(clean));
        }
        if (clean.length == 6) {
          clean = 'FF$clean';
        }
        return Color(int.parse('0x$clean'));
      } catch (_) {}
    }
    final lower = name.toLowerCase();
    if (lower.contains('travel')) return const Color(0xFFFF7A00);
    if (lower.contains('entertainment')) return const Color(0xFF8B5CF6);
    if (lower.contains('loan') || lower.contains('debt')) {
      return ZenioColors.primary;
    }
    if (lower.contains('food')) return const Color(0xFFEF4444);
    if (lower.contains('shop')) return const Color(0xFF3B82F6);
    return const Color(0xFF06B6D4);
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsNotifierProvider);
    final totalBalance = analyticsState.totalBalance;
    final allCategories = ref.watch(categoriesNotifierProvider);
    final allSpends = analyticsState.categorySpends;

    final homeState = ref.watch(homeNotifierProvider);
    final allTransactions = homeState.transactions;
    final filteredTxs = ref
        .read(analyticsNotifierProvider.notifier)
        .filterTransactions(allTransactions);

    int newestFirst(TransactionModel a, TransactionModel b) {
      final aDate = DateTimeUtils.parseTransactionDate(a.date) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTimeUtils.parseTransactionDate(b.date) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateComp = bDate.compareTo(aDate);
      if (dateComp != 0) return dateComp;
      return b.id.compareTo(a.id);
    }

    // Combine category definitions with their calculated spends
    final categoriesWithData = allCategories.map((cat) {
      final cleanCatName = cat.name.trim().toLowerCase();

      // Find matching spend model if available
      final matchSpend = allSpends.firstWhere(
        (s) => s.name.trim().toLowerCase() == cleanCatName,
        orElse: () => CategorySpendModel(
          id: cat.id,
          name: cat.name,
          amount: 0,
          spendsCount: 0,
          colorHex: '',
          iconName: cat.emoji,
        ),
      );

      // Find matching transactions in this category for this period & wallet (sorted latest first)
      final matchingTxs = filteredTxs.where((tx) {
        if (tx.resolvedKind != TransactionKind.expense) return false;
        return tx.title.trim().toLowerCase() == cleanCatName;
      }).toList()
        ..sort(newestFirst);

      final matchingAmount = matchingTxs.fold<double>(0.0, (sum, tx) => sum + tx.amount);
      final actualAmount = matchSpend.amount > 0 ? matchSpend.amount : matchingAmount;
      final actualCount = matchSpend.spendsCount > 0 ? matchSpend.spendsCount : matchingTxs.length;
      final effectiveSpend = matchSpend.copyWith(
        amount: actualAmount,
        spendsCount: actualCount,
      );

      return _CategoryWithData(
        item: cat,
        spend: effectiveSpend,
        transactions: matchingTxs,
        ratio: 0.0,
      );
    }).toList();

    // Spending filed under a title that is not (or is no longer) a category,
    // for example after renaming one or importing a file. Shown together so
    // the rows still add up to the total.
    final uncategorisedTxs = uncategorisedExpenses(
      filteredTxs,
      allCategories.map((c) => c.name),
    )..sort(newestFirst);
    if (uncategorisedTxs.isNotEmpty) {
      const uncategorised = CategoryItemModel(
        id: '_uncategorised',
        name: 'Uncategorised',
        emoji: '🗂️',
      );
      categoriesWithData.add(
        _CategoryWithData(
          item: uncategorised,
          spend: CategorySpendModel(
            id: uncategorised.id,
            name: uncategorised.name,
            amount: uncategorisedTxs.fold<double>(0, (sum, tx) => sum + tx.amount),
            spendsCount: uncategorisedTxs.length,
            colorHex: '',
            iconName: uncategorised.emoji,
          ),
          transactions: uncategorisedTxs,
          ratio: 0,
        ),
      );
    }

    final totalFromCategories = categoriesWithData.fold<double>(0.0, (sum, c) => sum + c.spend.amount);
    final effectiveTotalBalance = totalBalance > 0 ? totalBalance : totalFromCategories;

    final finalCategoriesWithData = categoriesWithData.map((c) {
      final ratio = effectiveTotalBalance > 0 ? (c.spend.amount / effectiveTotalBalance).clamp(0.0, 1.0) : 0.0;
      return _CategoryWithData(
        item: c.item,
        spend: c.spend,
        transactions: c.transactions,
        ratio: ratio,
      );
    }).toList();

    // Filter by tab
    var filtered = finalCategoriesWithData;
    if (_activeTab == CategoryFilterTab.active) {
      filtered = filtered.where((c) => c.spend.amount > 0).toList();
    } else if (_activeTab == CategoryFilterTab.zero) {
      filtered = filtered.where((c) => c.spend.amount == 0).toList();
    }

    // Sort
    switch (_sortOption) {
      case CategorySortOption.highestSpend:
        filtered.sort((a, b) => b.spend.amount.compareTo(a.spend.amount));
      case CategorySortOption.mostSpends:
        filtered.sort((a, b) => b.spend.spendsCount.compareTo(a.spend.spendsCount));
      case CategorySortOption.alphabetical:
        filtered.sort((a, b) => a.item.name.compareTo(b.item.name));
    }


    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenTitleBar(title: 'Spending by category'),
            // Dark Top Header Section (Exact match to Subscriptions & Debts)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Balance Display & + Manage Button Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // All spending for the chosen period and wallet.
                      Flexible(
                        child: HeadlineAmount(
                          amount: effectiveTotalBalance,
                          caption: analyticsState.spentCaption,
                        ),
                      ),

                      // + Manage Button Pill (Exact match to + Add in subscriptions & debts)
                      GestureDetector(
                        onTap: () {
                          ManageCategoriesBottomSheet.show(context);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 17,
                          ),
                          decoration: BoxDecoration(
                            color: ZenioColors.surfaceDark,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: ZenioColors.surfaceDarkBorder,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Manage',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom Row: Filter Dropdown Pills (Filter, Sort)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterDropdown(),
                        const SizedBox(width: 10),
                        _buildSortDropdown(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Light Curved Content Sheet (#F7F7F7)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: ZenioColors.sheet,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: filtered.isEmpty
                      ? const ListStateMessage(
                          title: 'No spending in this period',
                          message: 'Try another period or wallet.',
                          icon: Icons.pie_chart_outline_rounded,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(10, 16, 10, 20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final data = filtered[index];
                            final isExpanded =
                                _expandedCategoryId == data.item.id;

                            return _buildCategoryDetailCard(
                              data: data,
                              isExpanded: isExpanded,
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedCategoryId = null;
                                  } else {
                                    _expandedCategoryId = data.item.id;
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    Widget? leading,
    double? maxWidth,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ZenioColors.surfaceDark,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 6),
          ],
          if (maxWidth != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ZenioColors.border,
                ),
              ),
            )
          else
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ZenioColors.border,
              ),
            ),
          const SizedBox(width: 8),
          Assets.icons.dropDown.svg(
            width: 24,
            height: 24,
          ),
        ],
      ),
    );
  }



  Widget _buildFilterDropdown() {
    return PopupMenuButton<CategoryFilterTab>(
      offset: const Offset(0, 45),
      elevation: 8,
      onSelected: (tab) {
        setState(() {
          _activeTab = tab;
        });
      },
      color: ZenioColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ZenioColors.surfaceDarkBorder),
      ),
      child: _buildFilterPill(label: _activeTab.label),
      itemBuilder: (context) => CategoryFilterTab.values.map((tab) {
        final isSelected = _activeTab == tab;
        return PopupMenuItem<CategoryFilterTab>(
          value: tab,
          child: Text(
            tab.label,
            style: TextStyle(
              color: isSelected ? Colors.white : ZenioColors.border,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSortDropdown() {
    return PopupMenuButton<CategorySortOption>(
      offset: const Offset(0, 45),
      elevation: 8,
      onSelected: (opt) {
        setState(() {
          _sortOption = opt;
        });
      },
      color: ZenioColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ZenioColors.surfaceDarkBorder),
      ),
      child: _buildFilterPill(label: _sortOption.label),
      itemBuilder: (context) => CategorySortOption.values.map((opt) {
        final isSelected = _sortOption == opt;
        return PopupMenuItem<CategorySortOption>(
          value: opt,
          child: Text(
            opt.label,
            style: TextStyle(
              color: isSelected ? Colors.white : ZenioColors.border,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryDetailCard({
    required _CategoryWithData data,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    final catColor = _getCategoryColor(data.item.name, data.spend.colorHex);
    final badgeBg = _getBadgeBackgroundColor(data.item.name);
    final percent = data.ratio * 100;

    // Calculate metrics
    final currencySymbol = ref.watch(currencySymbolProvider);
    final totalSpent = data.spend.amount > 0
        ? data.spend.amount
        : data.transactions.fold<double>(0.0, (sum, t) => sum + t.amount);
    final txCount = data.transactions.isNotEmpty ? data.transactions.length : data.spend.spendsCount;
    final avgSpend = txCount > 0 ? (totalSpent / txCount) : 0.0;
    final maxSpend = data.transactions.isNotEmpty
        ? data.transactions.map((t) => t.amount).reduce((a, b) => a > b ? a : b)
        : totalSpent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: ZenioMotion.standard,
        curve: Curves.fastOutSlowIn,
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.fromLTRB(5, 5, 20, 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: 60x60 Circle Badge, Category Name & Spend Count, Amount
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      data.item.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        totalSpent > 0
                            ? (txCount > 0
                                ? '${AppNumberFormat.formatNumber(txCount)} ${txCount == 1 ? 'spend' : 'spends'} • ${percent.toStringAsFixed(1)}%'
                                : '${AppNumberFormat.formatNumber(data.spend.spendsCount)} spends • ${percent.toStringAsFixed(1)}%')
                            : 'No spends',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: ZenioColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Spending, written like every other amount: −₹3,698.
                AmountText(
                  totalSpent,
                  direction: MoneyDirection.outgoing,
                  color: totalSpent > 0 ? null : ZenioColors.textSecondary,
                ),
              ],
            ),

            // Expanded Detail Drawer (Sleek Animated Bar + Metrics + Transactions)
            AnimatedCrossFade(
              duration: ZenioMotion.standard,
              firstCurve: Curves.fastOutSlowIn,
              secondCurve: Curves.fastOutSlowIn,
              sizeCurve: Curves.fastOutSlowIn,
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(
                width: double.infinity,
                height: 0,
              ),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 0, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sleek Animated Progress Bar (only shown if ratio > 0)
                    if (data.ratio > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Share of Total Expenses',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ZenioColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${percent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: catColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECECEC),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: isExpanded ? data.ratio : 0,
                            ),
                            duration: ZenioMotion.slow,
                            curve: Curves.easeOutCubic,
                            builder: (context, animatedRatio, child) {
                              return FractionallySizedBox(
                                widthFactor: animatedRatio.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: catColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Metrics Row (Avg spend, Max spend)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: ZenioColors.sheet,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Average Spend',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ZenioColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  Money.balance(avgSpend, symbol: currencySymbol),
                                  style: AppFonts.numeric(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: ZenioColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: ZenioColors.sheet,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Highest Spend',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ZenioColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  Money.balance(maxSpend, symbol: currencySymbol),
                                  style: AppFonts.numeric(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: ZenioColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Transactions in this category Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: ZenioColors.textPrimary,
                          ),
                        ),
                        Text(
                          data.transactions.length > 5
                              ? 'Latest 5 of ${AppNumberFormat.formatNumber(data.transactions.length)}'
                              : '${AppNumberFormat.formatNumber(data.transactions.length)} total',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: ZenioColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Minimal & Redesigned Unified Transaction List (Max 5 items)
                    if (data.transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFEEEEEE),
                            width: 0.8,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'No transactions recorded for this category yet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: ZenioColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFEEEEEE),
                            width: 0.8,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            children: () {
                              final recentTxs = data.transactions.take(5).toList();
                              final items = <Widget>[];

                              for (var i = 0; i < recentTxs.length; i++) {
                                final tx = recentTxs[i];
                                final hasNote = tx.note != null && tx.note!.trim().isNotEmpty;
                                final titleText = hasNote
                                    ? tx.note!.trim()
                                    : (tx.bankName?.trim().isNotEmpty ?? false
                                        ? tx.bankName!.trim()
                                        : data.item.name);

                                final dateFormatted = _formatTxDate(tx.date);

                                items.add(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 9,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.arrow_downward_rounded,
                                              size: 13,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      titleText,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            ZenioColors.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  if (hasNote &&
                                                      tx.bankName != null &&
                                                      tx.bankName!.trim().isNotEmpty) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 6,
                                                        vertical: 1.5,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFFEFEFEF,),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                6,),
                                                      ),
                                                      child: Text(
                                                        tx.bankName!.trim(),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              Color(0xFF666666),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                dateFormatted,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w400,
                                                  color: ZenioColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          Money.signed(tx.amount, symbol: currencySymbol, direction: MoneyDirection.outgoing),
                                          style: AppFonts.numeric(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: ZenioColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                if (i < recentTxs.length - 1) {
                                  items.add(
                                    const Divider(
                                      height: 1,
                                      thickness: 0.6,
                                      indent: 48,
                                      endIndent: 12,
                                      color: Color(0xFFEFEFEF),
                                    ),
                                  );
                                }
                              }

                              return items;
                            }(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryWithData {
  _CategoryWithData({
    required this.item,
    required this.spend,
    required this.transactions,
    required this.ratio,
  });

  final CategoryItemModel item;
  final CategorySpendModel spend;
  final List<TransactionModel> transactions;
  final double ratio;
}
