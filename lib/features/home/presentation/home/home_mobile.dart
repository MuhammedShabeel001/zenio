import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/debts/debts.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/presentation/widgets/quick_action_item.dart';
import 'package:zenio/features/home/presentation/widgets/transaction_card.dart';
import 'package:zenio/features/split/split.dart';
import 'package:zenio/features/subscriptions/subscriptions.dart';
import 'package:zenio/features/transactions/transactions.dart';
import 'package:zenio/features/vault/vault.dart';
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
  String? _openTransactionId;

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
    final notifier = ref.read(homeNotifierProvider.notifier);
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
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
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
                          const SizedBox(height: 4),
                          const Text(
                            'Total balance',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF808080),
                            ),
                          ),
                        ],
                      ),
                      // Currency Badge Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 17,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF313131),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '₹',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currency,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Income & Expense Summary Cards
                  Row(
                    children: [
                      // Income Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1a1a),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFF313131),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Assets.icons.icome.svg(
                                    width: 24,
                                    height: 24,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '₹ ${NumberFormat('#,##0.00').format(income)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '+ ${incomeChange.toStringAsFixed(2)} %',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Expense Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1a1a),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFF313131),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Assets.icons.expense.svg(
                                    width: 24,
                                    height: 24,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '₹ ${NumberFormat('#,##0.00').format(expense)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '+ ${expenseChange.toStringAsFixed(2)} %',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDD3D34),
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
                    top: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          // Fixed Top Quick Actions & Section Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                            child: Column(
                              children: [
                                // Quick Actions Grid (Subscriptions, Debts, Split, Vault)
                                Row(
                                  children: [
                                    Expanded(
                                      child: QuickActionItem(
                                        label: 'Subscriptions',
                                        backgroundColor:
                                            const Color(0xFFFEF2D3),
                                        icon: Assets.icons.reccursion.svg(
                                          width: 28,
                                          height: 28,
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
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: QuickActionItem(
                                        label: 'Debts',
                                        backgroundColor:
                                            const Color(0xFFD6F6EB),
                                        icon: Assets.icons.debts.svg(
                                          width: 28,
                                          height: 28,
                                        ),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (context) =>
                                                  const DebtsScreenMobile(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: QuickActionItem(
                                        label: 'Split',
                                        backgroundColor:
                                            const Color(0xFFFDE3F0),
                                        icon: Assets.icons.split.svg(
                                          width: 28,
                                          height: 28,
                                        ),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (context) =>
                                                  const SplitScreenMobile(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: QuickActionItem(
                                        label: 'Vault',
                                        backgroundColor:
                                            const Color(0xFFDFEDFE),
                                        icon: Assets.icons.vault.svg(
                                          width: 28,
                                          height: 28,
                                        ),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (context) =>
                                                  const VaultScreenMobile(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),

                                // Transactions Section Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Transactions',
                                      style: TextStyle(
                                        fontSize: 20,
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
                                      child: Assets.icons.viewMore.svg(
                                        width: 24,
                                        height: 24,
                                        // colorFilter: const ColorFilter.mode(
                                        //   Color(0xFF10B981),
                                        //   BlendMode.srcIn,
                                        // ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Divider Line
                                const Divider(
                                  color: Color(0xFFE3E3E3),
                                  height: 1,
                                  thickness: 1,
                                ),
                              ],
                            ),
                          ),

                          // Scrollable Transactions List ONLY
                          Expanded(
                            child: ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 15, 10, 80),
                              children: [
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
                                    (tx) => TransactionCard(
                                      key: ValueKey(tx.id),
                                      transaction: tx,
                                      isOpen: _openTransactionId == tx.id,
                                      onOpen: () {
                                        if (_openTransactionId != tx.id) {
                                          setState(() {
                                            _openTransactionId = tx.id;
                                          });
                                        }
                                      },
                                      onClose: () {
                                        if (_openTransactionId == tx.id) {
                                          setState(() {
                                            _openTransactionId = null;
                                          });
                                        }
                                      },
                                      onDelete: () {
                                        notifier.deleteTransaction(tx.id);
                                        ref
                                            .read(transactionsNotifierProvider.notifier)
                                            .deleteTransaction(tx.id);
                                      },
                                      onEdit: () {
                                        AddTransactionBottomSheet.show(context);
                                      },
                                    ),
                                  ),
                              ],
                            ),
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
