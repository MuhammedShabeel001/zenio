import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/presentation/widgets/quick_action_item.dart';
import 'package:zenio/features/home/presentation/widgets/transaction_card.dart';
import 'package:zenio/features/subscriptions/subscriptions.dart';
import 'package:zenio/features/transactions/transactions.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/add_transaction_bottom_sheet.dart';
import 'package:zenio/shared/widgets/custom_navigation_bar.dart';

class HomeScreenMobile extends ConsumerStatefulWidget {
  const HomeScreenMobile({
    this.onTabSelected,
    super.key,
  });

  final ValueChanged<int>? onTabSelected;

  @override
  ConsumerState<HomeScreenMobile> createState() => _HomeScreenMobileState();
}

class _HomeScreenMobileState extends ConsumerState<HomeScreenMobile> {
  int _selectedNavIndex = 0;

  String _formatWholePart(double amount) {
    final whole = amount.toInt();
    final formatter = NumberFormat('#,##0');
    return formatter.format(whole);
  }

  String _formatDecimalPart(double amount) {
    final decimal = ((amount - amount.toInt()).abs() * 100).round();
    return '.${decimal.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeNotifierProvider);
    final summary = state.summary;
    final transactions = state.transactions;

    final totalBalance = summary?.totalBalance ?? 23678.01;
    final income = summary?.income ?? 23678.01;
    final incomeChange = summary?.incomeChangePercentage ?? 12.06;
    final expense = summary?.expense ?? 23678.01;
    final expenseChange = summary?.expenseChangePercentage ?? 12.06;
    final currency = summary?.selectedCurrency ?? 'INR';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Dark Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Balance Row & Currency Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: '₹ ',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: _formatWholePart(totalBalance),
                                  style: const TextStyle(
                                    fontSize: 34,
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
                                    color: Color(0xFF7A7A80),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Total balance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                      // Currency Badge Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF19191B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF2C2C2E),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currency,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Income & Expense Summary Cards
                  Row(
                    children: [
                      // Income Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF171719),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF262628),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Income',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFE5E5E5),
                                    ),
                                  ),
                                  Assets.icons.icome.svg(
                                    width: 18,
                                    height: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '₹ ${NumberFormat('#,##0.00').format(income)}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '+ ${incomeChange.toStringAsFixed(2)} %',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2CC56F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Expense Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF171719),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF262628),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Expense',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFE5E5E5),
                                    ),
                                  ),
                                  Assets.icons.expense.svg(
                                    width: 18,
                                    height: 18,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '₹ ${NumberFormat('#,##0.00').format(expense)}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '+ ${expenseChange.toStringAsFixed(2)} %',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Curved Light Content Container Sheet with Floating Navigation Bar
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                  child: Stack(
                    children: [
                      // Scrollable Main Content
                      ListView(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
                        children: [
                          // Quick Actions Grid (Subscriptions, Debts, Split, Vault)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              QuickActionItem(
                                label: 'Subscriptions',
                                backgroundColor: const Color(0xFFFEF7DA),
                                icon: Assets.icons.reccursion.svg(
                                  width: 26,
                                  height: 26,
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) =>
                                          const SubscriptionsScreenMobile(),
                                    ),
                                  );
                                },
                              ),
                              QuickActionItem(
                                label: 'Debts',
                                backgroundColor: const Color(0xFFE0F8EC),
                                icon: Assets.icons.debts.svg(
                                  width: 26,
                                  height: 26,
                                ),
                              ),
                              QuickActionItem(
                                label: 'Split',
                                backgroundColor: const Color(0xFFFDE7F3),
                                icon: Assets.icons.split.svg(
                                  width: 26,
                                  height: 26,
                                ),
                              ),
                              QuickActionItem(
                                label: 'Vault',
                                backgroundColor: const Color(0xFFE3F0FF),
                                icon: Assets.icons.vault.svg(
                                  width: 26,
                                  height: 26,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Transactions Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Transactions',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111111),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) =>
                                          const TransactionsScreenMobile(),
                                    ),
                                  );
                                },
                                child: Assets.icons.rightArrow.svg(
                                  width: 22,
                                  height: 22,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF2CC56F),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Divider Line
                          const Divider(
                            color: Color(0xFFECECEC),
                            height: 1,
                            thickness: 1,
                          ),
                          const SizedBox(height: 16),

                          // Transactions List
                          if (transactions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...transactions.map(
                              (tx) => TransactionCard(transaction: tx),
                            ),
                        ],
                      ),

                      // Floating Bottom Navigation Bar
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: CustomNavigationBar(
                          selectedIndex: _selectedNavIndex,
                          onTabSelected: (index) {
                            setState(() {
                              _selectedNavIndex = index;
                            });
                            widget.onTabSelected?.call(index);
                          },
                          onAddTap: () {
                            AddTransactionBottomSheet.show(context);
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
}
