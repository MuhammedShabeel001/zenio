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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CategorySortOption _sortOption = CategorySortOption.highestSpend;
  CategoryFilterTab _activeTab = CategoryFilterTab.all;
  String? _expandedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    // Filter by search query
    var filtered = categoriesWithData;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (c) => c.item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Filter by tab
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
            // Dark Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Row (Back Button, Title, + New Button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF313131),
                            ),
                          ),
                          child: Center(
                            child: Assets.icons.leftArrow.svg(
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ManageCategoriesBottomSheet.show(context);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF313131),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Manage',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
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

                  // Total Spent Display & Subtitle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Expenses',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9E9EA5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: '₹ ',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: _formatWholePart(totalBalance),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: _formatDecimalPart(totalBalance),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF808080),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF313131),
                          ),
                        ),
                        child: Text(
                          '${allCategories.length} Categories',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD1D1D6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Light Curved Content Sheet
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
                  child: Column(
                    children: [
                      // Search & Quick Filter Controls
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Column(
                          children: [
                            // Search Field
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: Color(0xFF8E8E93),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF111111),
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Search categories...',
                                        hintStyle: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF9E9EA5),
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _searchQuery = val.trim();
                                        });
                                      },
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Filter Tabs & Sort Dropdown Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Tabs (All, Active, Zero)
                                Row(
                                  children: CategoryFilterTab.values.map((tab) {
                                    final isSelected = _activeTab == tab;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _activeTab = tab;
                                        });
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF111111)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          tab.label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF8E8E93),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                                // Sort Selector
                                PopupMenuButton<CategorySortOption>(
                                  initialValue: _sortOption,
                                  onSelected: (val) {
                                    setState(() {
                                      _sortOption = val;
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: Colors.white,
                                  elevation: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.sort_rounded,
                                          size: 15,
                                          color: Color(0xFF8E8E93),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _sortOption.label,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111111),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  itemBuilder: (context) {
                                    return CategorySortOption.values.map((opt) {
                                      return PopupMenuItem<CategorySortOption>(
                                        value: opt,
                                        child: Text(
                                          opt.label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: _sortOption == opt
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: _sortOption == opt
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF111111),
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Category Cards List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEBEBEB),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '🏷️',
                                          style: TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No categories found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Try a different search keyword'
                                          : 'Tap Manage to add a new category',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Emoji, Name, Spends Count, Amount, Chevron
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
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
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        txCount > 0
                            ? '$txCount ${txCount == 1 ? 'spend' : 'spends'} • ${percent.toStringAsFixed(1)}%'
                            : 'No spends',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9E9EA5),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          totalSpent > 0 ? '- ${_formatAmount(totalSpent)}' : '₹ 0',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          'INR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Share Progress Bar
            if (data.ratio > 0) ...[
              const SizedBox(height: 10),
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFECECEC),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: data.ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: catColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],

            // Expanded Detail Drawer (Transactions list + Analytics)
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
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(color: Color(0xFFECECEC), height: 1),
                    const SizedBox(height: 12),

                    // Metrics Row (Avg spend, Max spend)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(16),
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
                                const SizedBox(height: 2),
                                Text(
                                  '₹ ${_formatAmount(avgSpend)}',
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
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(16),
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
                                const SizedBox(height: 2),
                                Text(
                                  '₹ ${_formatAmount(maxSpend)}',
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
                        padding: const EdgeInsets.all(16),
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
                              horizontal: 12,
                              vertical: 8,
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
                                  '- ₹ ${_formatAmount(tx.amount)}',
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
