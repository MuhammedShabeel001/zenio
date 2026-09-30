import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/debts/debts.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/presentation/widgets/delete_transaction_with_undo.dart';
import 'package:zenio/features/home/presentation/widgets/quick_action_item.dart';
import 'package:zenio/features/home/presentation/widgets/transaction_card.dart';
import 'package:zenio/features/split/split.dart';
import 'package:zenio/features/subscriptions/subscriptions.dart';
import 'package:zenio/features/transactions/presentation/widgets/edit_transaction_dialog.dart';
import 'package:zenio/features/transactions/transactions.dart';
import 'package:zenio/features/vault/vault.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/utils/formatters.dart';
import 'package:zenio/shared/widgets/add_transaction_bottom_sheet.dart';
import 'package:zenio/shared/widgets/custom_navigation_bar.dart';
import 'package:zenio/shared/widgets/inserted_item.dart';
import 'package:zenio/shared/widgets/list_state_message.dart';
import 'package:zenio/shared/widgets/money.dart';

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
  String? _openTransactionId;

  /// Set once the loaded list has been shown: from then on, new rows animate
  /// in, while the first appearance of the list does not.
  bool _listShown = false;

  /// "+12% vs last month".
  static String _changeText(double change) {
    final percent = change.round();
    final sign = percent > 0 ? '+' : (percent < 0 ? Money.minus : '');
    return '$sign${percent.abs()}% vs last month';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeNotifierProvider);
    final notifier = ref.read(homeNotifierProvider.notifier);
    if (!_listShown && state.status == HomeStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _listShown = true);
    }
    final summary = state.summary;
    final transactions = state.transactions;

    // Only the total matters here; watching the whole wallet state would
    // rebuild Home (kept alive in the tab shell) on every card swipe.
    final totalBalance =
        ref.watch(walletNotifierProvider.select((s) => s.cardBalance));
    final frozenWallets = ref.watch(
      walletNotifierProvider.select(
        (s) => s.cards.where((c) => c.isFrozen).length,
      ),
    );
    final income = summary?.income ?? 0.0;
    final incomeChange = summary?.incomeChangePercentage;
    final expense = summary?.expense ?? 0.0;
    final expenseChange = summary?.expenseChangePercentage;
    final currencySymbol = ref.watch(currencySymbolProvider);

    // More income is good news, more spending is not.
    final incomeChangeColor = (incomeChange ?? 0) >= 0
        ? ZenioColors.primary
        : ZenioColors.dangerOnDark;
    final expenseChangeColor = (expenseChange ?? 0) > 0
        ? ZenioColors.dangerOnDark
        : ZenioColors.primary;

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
                  // Total balance. The display currency is chosen in
                  // Settings, where it is explained.
                  HeadlineAmount(
                    amount: totalBalance,
                    caption: frozenWallets == 0
                        ? 'Total balance'
                        : 'Total balance · excludes $frozenWallets frozen '
                            'wallet${frozenWallets == 1 ? '' : 's'}',
                  ),
                  const SizedBox(height: 20),

                  // Income & Expense Summary Cards
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'This month',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ZenioColors.textOnDarkSecondary,
                      ),
                    ),
                  ),
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
                            color: ZenioColors.surfaceDark,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: ZenioColors.surfaceDarkBorder,
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
                                '$currencySymbol ${AppNumberFormat.formatAmount(income, alwaysShowDecimals: true)}',
                                style: AppFonts.numeric(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (incomeChange != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _changeText(incomeChange),
                                  style: AppFonts.numeric(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: incomeChangeColor,
                                  ),
                                ),
                              ],
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
                            color: ZenioColors.surfaceDark,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: ZenioColors.surfaceDarkBorder,
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
                                '$currencySymbol ${AppNumberFormat.formatAmount(expense, alwaysShowDecimals: true)}',
                                style: AppFonts.numeric(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (expenseChange != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _changeText(expenseChange),
                                  style: AppFonts.numeric(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: expenseChangeColor,
                                  ),
                                ),
                              ],
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
                  color: ZenioColors.sheet,
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
                                        onTap: () => openVault(context, ref),
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
                                        color: ZenioColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (context) =>
                                                const TransactionsScreenMobile(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF047857),
                                        minimumSize: const Size(48, 48),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'See all',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          ExcludeSemantics(
                                            child: Assets.icons.viewMore.svg(
                                              width: 20,
                                              height: 20,
                                            ),
                                          ),
                                        ],
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
                                  EdgeInsets.fromLTRB(
                                    10,
                                    15,
                                    10,
                                    CustomNavigationBar.reservedHeight(context),
                                  ),
                              children: [
                                if (transactions.isEmpty)
                                  switch (state.status) {
                                    HomeStatus.initial ||
                                    HomeStatus.loading =>
                                      const ListStateMessage.loading(),
                                    HomeStatus.error => ListStateMessage.error(
                                        onRetry: notifier.loadMoneyTrackerData,
                                      ),
                                    HomeStatus.success => ListStateMessage(
                                        title: 'No transactions yet',
                                        message:
                                            'Your spending and income will show up here once you add them.',
                                        icon: Icons.receipt_long_outlined,
                                        actionLabel: 'Add transaction',
                                        onAction: () =>
                                            AddTransactionBottomSheet.show(context),
                                      ),
                                  }
                                else
                                  ...transactions.take(10).map(
                                    // A transaction added (or restored by
                                    // Undo) while Home is showing eases in.
                                    (tx) => InsertedItem(
                                      key: ValueKey(tx.id),
                                      animate: _listShown,
                                      child: TransactionCard(
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
                                      onDelete: () => deleteTransactionWithUndo(
                                        context,
                                        ref,
                                        tx.id,
                                      ),
                                      // Adjustments can't be edited, so
                                      // they offer no Edit at all.
                                      onEdit: tx.resolvedKind ==
                                              TransactionKind.adjustment
                                          ? null
                                          : () => EditTransactionDialog.show(
                                                context,
                                                transaction: tx,
                                              ),
                                    ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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
