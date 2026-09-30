import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/debts/debts.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/presentation/widgets/delete_transaction_with_undo.dart';
import 'package:zenio/features/home/presentation/widgets/quick_action_item.dart';
import 'package:zenio/features/home/presentation/widgets/transaction_card.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
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
import 'package:zenio/shared/widgets/list_state_message.dart';

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

  String _formatWholePart(double amount) =>
      AppNumberFormat.formatWholePart(amount);

  String _formatDecimalPart(double amount) =>
      AppNumberFormat.formatDecimalPart(amount);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeNotifierProvider);
    final notifier = ref.read(homeNotifierProvider.notifier);
    final summary = state.summary;
    final transactions = state.transactions;

    // Only the total matters here; watching the whole wallet state would
    // rebuild Home (kept alive in the tab shell) on every card swipe.
    final totalBalance =
        ref.watch(walletNotifierProvider.select((s) => s.cardBalance));
    final income = summary?.income ?? 0.0;
    final incomeChange = summary?.incomeChangePercentage ?? 0.0;
    final expense = summary?.expense ?? 0.0;
    final expenseChange = summary?.expenseChangePercentage ?? 0.0;
    final currency = ref.watch(currencyCodeProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    final formattedIncomeChange = incomeChange >= 0
        ? '+ ${AppNumberFormat.formatAmount(incomeChange, alwaysShowDecimals: true)} %'
        : '- ${AppNumberFormat.formatAmount(incomeChange.abs(), alwaysShowDecimals: true)} %';
    final incomeChangeColor = incomeChange >= 0
        ? ZenioColors.primary
        : ZenioColors.danger;

    final formattedExpenseChange = expenseChange >= 0
        ? '+ ${AppNumberFormat.formatAmount(expenseChange, alwaysShowDecimals: true)} %'
        : '- ${AppNumberFormat.formatAmount(expenseChange.abs(), alwaysShowDecimals: true)} %';
    final expenseChangeColor = expenseChange >= 0
        ? ZenioColors.danger
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
                  // Top Balance Row & Currency Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        // Large amounts and text sizes shrink to fit instead of overflowing.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$currencySymbol ',
                                      style: AppFonts.numeric(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: _formatWholePart(totalBalance),
                                      style: AppFonts.numeric(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: _formatDecimalPart(totalBalance),
                                      style: AppFonts.numeric(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF808080),
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
                        ),
                      ),
                      // Currency Badge Pill
                      Theme(
                        data: Theme.of(context).copyWith(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: PopupMenuButton<String>(
                          tooltip: 'Select Currency',
                          elevation: 12,
                          shadowColor: Colors.black.withValues(alpha: 0.25),
                          color: const Color(0xFF1E1E1E),
                          surfaceTintColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 190,
                            maxWidth: 220,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: Color(0xFF313131),
                              width: 1.2,
                            ),
                          ),
                          offset: const Offset(0, 52),
                          onSelected: (String code) {
                            ref
                                .read(settingsNotifierProvider.notifier)
                                .updatePrimaryCurrency(code);
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: 'INR',
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2C2520),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '₹',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFDB965),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'INR',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Indian Rupee',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: ZenioColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (currency.toUpperCase() == 'INR')
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: ZenioColors.primary,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              enabled: false,
                              height: 1,
                              padding: EdgeInsets.zero,
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFF313131),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'DLR',
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E2D27),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        r'$',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: ZenioColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'DLR',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'US Dollar',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: ZenioColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (currency.toUpperCase() == 'DLR')
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: ZenioColors.primary,
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1a1a1a),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFF313131),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currencySymbol,
                                  style: const TextStyle(
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
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: ZenioColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
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
                                '$currencySymbol ${AppNumberFormat.formatAmount(income, alwaysShowDecimals: true)}',
                                style: AppFonts.numeric(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formattedIncomeChange,
                                style: AppFonts.numeric(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: incomeChangeColor,
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
                                '$currencySymbol ${AppNumberFormat.formatAmount(expense, alwaysShowDecimals: true)}',
                                style: AppFonts.numeric(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formattedExpenseChange,
                                style: AppFonts.numeric(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: expenseChangeColor,
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
                                      onDelete: () => deleteTransactionWithUndo(
                                        context,
                                        ref,
                                        tx.id,
                                      ),
                                      onEdit: () {
                                        EditTransactionDialog.show(
                                          context,
                                          transaction: tx,
                                        );
                                      },
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
