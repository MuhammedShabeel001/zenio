import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/analytics/controller/analytics/analytics_notifier.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/transactions/domain/models/category_item_model.dart';
import 'package:zenio/features/transactions/presentation/widgets/manage_categories_bottom_sheet.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
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

  String _formatAmount(double amount) {
    if (amount == amount.toInt()) {
      return NumberFormat('#,##0').format(amount.toInt());
    }
    return NumberFormat('#,##0.00').format(amount);
  }

  String _formatWholePart(double amount) {
    final whole = amount.toInt();
    return NumberFormat('#,##0').format(whole);
  }

  String _formatDecimalPart(double amount) {
    final decimal = ((amount - amount.toInt()).abs() * 100).round();
    return '.${decimal.toString().padLeft(2, '0')}';
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
      return const Color(0xFF10B981);
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

      // Find matching transactions in this category for this period
      final matchingTxs = allTransactions.where((tx) {
        if (tx.isIncome || tx.title.startsWith('Transfer to')) return false;
        return tx.title.trim().toLowerCase() == cleanCatName;
      }).toList();

      final ratio = totalBalance > 0 ? (matchSpend.amount / totalBalance).clamp(0.0, 1.0) : 0.0;

      return _CategoryWithData(
        item: cat,
        spend: matchSpend,
        transactions: matchingTxs,
        ratio: ratio,
      );
    }).toList();

    // Filter by tab
    var filtered = categoriesWithData;
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

    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyCode = ref.watch(currencyCodeProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Dark Top Header Section (Exact match to Subscriptions & Debts)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Balance Display & + Manage Button Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Balance
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$currencySymbol ',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: _formatWholePart(totalBalance),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: _formatDecimalPart(totalBalance),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF808080),
                              ),
                            ),
                          ],
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
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFF313131),
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

                  // Bottom Row: Filter Dropdown Pills (Exact match to Subscriptions & Debts)
                  Row(
                    children: [
                      _buildFilterDropdown(),
                      const SizedBox(width: 10),
                      _buildSortDropdown(),
                    ],
                  ),
                ],
              ),
            ),

            // Light Curved Content Sheet (#F7F7F7)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No categories found',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
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

  Widget _buildFilterPill({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD1D1D6),
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
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF313131)),
      ),
      child: _buildFilterPill(label: _activeTab.label),
      itemBuilder: (context) => CategoryFilterTab.values.map((tab) {
        final isSelected = _activeTab == tab;
        return PopupMenuItem<CategoryFilterTab>(
          value: tab,
          child: Text(
            tab.label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFD1D1D6),
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
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF313131)),
      ),
      child: _buildFilterPill(label: _sortOption.label),
      itemBuilder: (context) => CategorySortOption.values.map((opt) {
        final isSelected = _sortOption == opt;
        return PopupMenuItem<CategorySortOption>(
          value: opt,
          child: Text(
            opt.label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFD1D1D6),
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
    final currencyCode = ref.watch(currencyCodeProvider);
    final totalSpent = data.spend.amount;
    final txCount = data.transactions.length;
    final avgSpend = txCount > 0 ? (totalSpent / txCount) : 0.0;
    final maxSpend = txCount > 0
        ? data.transactions.map((t) => t.amount).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
                                ? '$txCount ${txCount == 1 ? 'spend' : 'spends'} • ${percent.toStringAsFixed(1)}%'
                                : '${data.spend.spendsCount} spends • ${percent.toStringAsFixed(1)}%')
                            : 'No spends',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFB2B2B2),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      totalSpent > 0 ? '- ${_formatAmount(totalSpent)}' : '$currencySymbol 0',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: totalSpent > 0
                            ? const Color(0xFF000000)
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currencyCode,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Expanded Detail Drawer (Sleek Animated Bar + Metrics + Transactions)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
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
                              color: Color(0xFF8E8E93),
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
                            duration: const Duration(milliseconds: 400),
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
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Average Spend',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8E8E93),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$currencySymbol ${_formatAmount(avgSpend)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111111),
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
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Highest Spend',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8E8E93),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '$currencySymbol ${_formatAmount(maxSpend)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111111),
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
                            color: Color(0xFF111111),
                          ),
                        ),
                        Text(
                          '${data.transactions.length} total',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Transactions List
                    if (data.transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'No transactions recorded for this category yet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: data.transactions.take(5).map((tx) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.note != null && tx.note!.isNotEmpty
                                            ? tx.note!
                                            : tx.bankName ?? 'Transaction',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF111111),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tx.date,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '- $currencySymbol ${_formatAmount(tx.amount)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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
