import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/home.dart';
import 'package:zenio/features/home/presentation/widgets/delete_transaction_with_undo.dart';
import 'package:zenio/features/transactions/controller/transactions/transactions_notifier.dart';
import 'package:zenio/features/transactions/presentation/widgets/adjustment_details_dialog.dart';
import 'package:zenio/features/transactions/presentation/widgets/edit_transaction_dialog.dart';
import 'package:zenio/features/transactions/presentation/widgets/transaction_detail_card.dart';
import 'package:zenio/shared/shared.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/utils/period_filter.dart';

class TransactionsScreenMobile extends ConsumerStatefulWidget {
  const TransactionsScreenMobile({super.key});

  @override
  ConsumerState<TransactionsScreenMobile> createState() =>
      _TransactionsScreenMobileState();
}

class _TransactionsScreenMobileState
    extends ConsumerState<TransactionsScreenMobile> {
  String? _openTransactionId;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsNotifierProvider);
    final transactions = state.transactions;
    final hasAnyTransactions = ref.watch(
      homeNotifierProvider.select((s) => s.transactions.isNotEmpty),
    );
    final loadFailed = ref.watch(
      homeNotifierProvider.select((s) => s.status == HomeStatus.error),
    );
    // Spending in the shown period, worked out with the filtered list.
    final totalExpenses = state.totalBalance;


    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenTitleBar(title: 'Transactions'),
            // Dark Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Balance Display & + Add Button Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Spending in the shown period.
                      Flexible(
                        child: HeadlineAmount(
                          amount: totalExpenses,
                          caption: 'Spent · ${periodLabel(
                            state.selectedPeriod,
                            state.selectedTimeframe,
                          )}',
                        ),
                      ),

                      // + Add Button Pill
                      GestureDetector(
                        onTap: () {
                          AddTransactionBottomSheet.show(context);
                        },
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
                              width: 1,
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
                                'Add',
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
                  const SizedBox(height: 13),

                  // Bottom Row: Filter Dropdown Pills
                  Row(
                    children: [
                      _buildPeriodPicker(state.selectedPeriod),
                      const SizedBox(width: 10),
                      _buildTimeframePicker(
                          state.selectedPeriod, state.selectedTimeframe,),
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
                  color: ZenioColors.sheet,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  // Built lazily: the list can hold every transaction ever made.
                  child: transactions.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(10, 16, 10, 20),
                          children: [
                            if (state.isLoading)
                              const ListStateMessage.loading()
                            else if (loadFailed)
                              ListStateMessage.error(
                                onRetry: ref
                                    .read(homeNotifierProvider.notifier)
                                    .loadMoneyTrackerData,
                              )
                            else if (!hasAnyTransactions)
                              ListStateMessage(
                                title: 'No transactions yet',
                                message:
                                    'Your spending and income will show up here once you add them.',
                                icon: Icons.receipt_long_outlined,
                                actionLabel: 'Add transaction',
                                onAction: () =>
                                    AddTransactionBottomSheet.show(context),
                              )
                            else
                              ListStateMessage(
                                title: 'Nothing in this period',
                                message:
                                    'No transactions for ${state.selectedTimeframe.toLowerCase() == 'all time' ? 'this filter' : state.selectedTimeframe}. Try another period.',
                                icon: Icons.event_busy_outlined,
                              ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(10, 16, 10, 20),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final item = transactions[index];
                            return TransactionDetailCard(
                              key: ValueKey(item.id),
                              transaction: item,
                              isOpen: _openTransactionId == item.id,
                              // An adjustment can't be edited; a tap
                              // shows what it did.
                              onTap: () => showAdjustmentDetails(
                                context,
                                ref,
                                item.toModel(),
                              ),
                              onOpen: () {
                                if (_openTransactionId != item.id) {
                                  setState(() {
                                    _openTransactionId = item.id;
                                  });
                                }
                              },
                              onClose: () {
                                if (_openTransactionId == item.id) {
                                  setState(() {
                                    _openTransactionId = null;
                                  });
                                }
                              },
                              onDelete: () => deleteTransactionWithUndo(
                                context,
                                ref,
                                item.id,
                              ),
                              // Adjustments can't be edited, so they offer
                              // no Edit at all.
                              onEdit: item.resolvedKind ==
                                      TransactionKind.adjustment
                                  ? null
                                  : () => EditTransactionDialog.show(
                                        context,
                                        transaction: item,
                                      ),
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
    // 7pt of invisible padding above and below makes the tap target 48pt;
    // the space around the pill row is reduced by the same amount.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ZenioColors.surfaceDark,
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
      ),
    );
  }

  Widget _buildPeriodPicker(String currentPeriod) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      elevation: 8,
      onSelected: (value) {
        ref.read(transactionsNotifierProvider.notifier).updatePeriod(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'Daily',
          child: Text('Daily',
              style: TextStyle(
                  color: ZenioColors.border,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,),),
        ),
        const PopupMenuItem(
          value: 'Weekly',
          child: Text('Weekly',
              style: TextStyle(
                  color: ZenioColors.border,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,),),
        ),
        const PopupMenuItem(
          value: 'Monthly',
          child: Text('Monthly',
              style: TextStyle(
                  color: ZenioColors.border,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,),),
        ),
        const PopupMenuItem(
          value: 'Custom',
          child: Text('Custom',
              style: TextStyle(
                  color: ZenioColors.border,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,),),
        ),
      ],
      color: ZenioColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ZenioColors.surfaceDarkBorder, width: 1),
      ),
      child: _buildFilterPill(label: currentPeriod),
    );
  }

  Widget _buildTimeframePicker(String period, String timeframe) {
    if (period.toLowerCase() == 'custom') {
      return GestureDetector(
        // The whole pill, padding included, is tappable.
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          List<DateTime?> selectedDates = [];
          final picked = await showModalBottomSheet<List<DateTime?>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: ZenioColors.surfaceDark,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                      top: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: ZenioColors.surfaceDarkBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Text(
                          'Choose dates',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,),
                        ),
                        CalendarDatePicker2(
                          config: CalendarDatePicker2Config(
                            calendarType: CalendarDatePicker2Type.range,
                            selectedDayHighlightColor: Colors.white,
                            selectedRangeHighlightColor:
                                Colors.white.withOpacity(0.15),
                            selectedDayTextStyle: AppFonts.numeric(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,),
                            dayTextStyle: AppFonts.numeric(color: Colors.white),
                            disabledDayTextStyle: AppFonts.numeric(
                                color: ZenioColors.surfaceDarkBorder,),
                            yearTextStyle:
                                AppFonts.numeric(color: Colors.white),
                            monthTextStyle:
                                const TextStyle(color: Colors.white),
                            controlsTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,),
                            weekdayLabelTextStyle:
                                const TextStyle(color: ZenioColors.border),
                            lastDate: DateTime.now(),
                            firstDate: DateTime(2000),
                          ),
                          value: selectedDates,
                          onValueChanged: (dates) {
                            setState(() {
                              selectedDates = dates;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16,),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      side: const BorderSide(
                                          color: ZenioColors.surfaceDarkBorder,),
                                    ),
                                  ),
                                  child: const Text('Cancel',
                                      style: TextStyle(color: Colors.white),),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: selectedDates.length == 2 &&
                                          selectedDates[0] != null &&
                                          selectedDates[1] != null
                                      ? () =>
                                          Navigator.pop(context, selectedDates)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16,),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    disabledBackgroundColor:
                                        Colors.white.withOpacity(0.3),
                                  ),
                                  child: const Text('Apply',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,),),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
          if (picked != null &&
              picked.length == 2 &&
              picked[0] != null &&
              picked[1] != null) {
            ref
                .read(transactionsNotifierProvider.notifier)
                .updateTimeframe(customRangeTimeframe(picked[0]!, picked[1]!));
          }
        },
        child: _buildFilterPill(label: timeframe),
      );
    }

    List<String> options = [];
    if (period.toLowerCase() == 'daily') {
      options = ['Today', 'Yesterday'];
    } else if (period.toLowerCase() == 'weekly') {
      options = ['This week', 'Last week'];
    } else if (period.toLowerCase() == 'monthly') {
      options = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      elevation: 8,
      constraints: const BoxConstraints(maxHeight: 250),
      onSelected: (value) {
        ref.read(transactionsNotifierProvider.notifier).updateTimeframe(value);
      },
      itemBuilder: (context) => options
          .map((opt) => PopupMenuItem(
                value: opt,
                child: Text(opt,
                    style: const TextStyle(
                        color: ZenioColors.border,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,),),
              ),)
          .toList(),
      color: ZenioColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ZenioColors.surfaceDarkBorder, width: 1),
      ),
      child: _buildFilterPill(label: timeframe),
    );
  }
}
