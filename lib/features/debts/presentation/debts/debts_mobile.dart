import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/debts/controller/debts/debts_notifier.dart';
import 'package:zenio/features/debts/presentation/widgets/add_debt_bottom_sheet.dart';
import 'package:zenio/features/debts/presentation/widgets/debt_card.dart';
import 'package:zenio/features/debts/presentation/widgets/edit_debt_dialog.dart';
import 'package:zenio/shared/shared.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/delete_with_undo.dart';

class DebtsScreenMobile extends ConsumerStatefulWidget {
  const DebtsScreenMobile({super.key});

  @override
  ConsumerState<DebtsScreenMobile> createState() => _DebtsScreenMobileState();
}

class _DebtsScreenMobileState extends ConsumerState<DebtsScreenMobile> {
  String? _openDebtId;
  String? _expandedTileId;
  /// Says which way the headline amount goes, since it is shown without a
  /// sign: "Net · You're owed", "You owe in total", and so on.
  static String _totalCaption(String filter, double net) {
    if (filter == 'I Owe') return 'You owe in total';
    if (filter == 'Owed to me') return 'Owed to you in total';
    if ((net * 100).round() == 0) return 'Net · All settled';
    return net > 0 ? "Net · You're owed" : 'Net · You owe';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(debtsNotifierProvider);
    final debts = state.debts;

    final filteredDebts = debts.where((debt) {
      if (state.selectedFilter == 'I Owe') return debt.isOwed;
      if (state.selectedFilter == 'Owed to me') return !debt.isOwed;
      return true;
    }).toList();

    double totalBalance = 0.0;
    for (final debt in filteredDebts) {
      if (debt.isOwed) {
        totalBalance -= debt.amount;
      } else {
        totalBalance += debt.amount;
      }
    }


    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenTitleBar(title: 'Debts'),
            // Dark Top Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Balance Display & + Add Button Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // What is owed, and which way.
                      Flexible(
                        child: HeadlineAmount(
                          amount: totalBalance.abs(),
                          caption: _totalCaption(
                            state.selectedFilter,
                            totalBalance,
                          ),
                        ),
                      ),

                      // + Add Button Pill
                      GestureDetector(
                        onTap: () {
                          AddDebtBottomSheet.show(context);
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

                  // Bottom Row: Filter Dropdown Pill (Debts v)
                  Row(
                    children: [
                      // The filter's value stays 'I Owe'; it reads in sentence case.
                      _buildFilterPill(
                        label: state.selectedFilter == 'I Owe'
                            ? 'I owe'
                            : state.selectedFilter,
                      ),
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(10, 16, 10, 20),
                    children: [
                      if (filteredDebts.isEmpty) ...[
                        if (state.isLoading)
                          const ListStateMessage.loading()
                        else if (debts.isEmpty && state.errorMessage != null)
                          ListStateMessage.error(
                            onRetry: ref.read(debtsNotifierProvider.notifier).loadData,
                          )
                        else if (debts.isEmpty)
                          ListStateMessage(
                            title: 'No debts yet',
                            message:
                                'Keep track of money you owe and money owed to you.',
                            icon: Icons.handshake_outlined,
                            actionLabel: 'Add debt',
                            onAction: () => AddDebtBottomSheet.show(context),
                          )
                        else
                          const ListStateMessage(
                            title: 'Nothing here',
                            message: 'No debts match this filter.',
                            icon: Icons.filter_alt_off_outlined,
                          ),
                      ] else
                        ...filteredDebts.map(
                          (item) => DebtCard(
                            key: ValueKey('${item.id}_${item.isOwed}'),
                            debt: item,
                            isOpen: _openDebtId == item.id,
                            isTileExpanded: _expandedTileId == item.id,
                            onTileTap: () {
                              setState(() {
                                if (_expandedTileId == item.id) {
                                  _expandedTileId = null;
                                } else {
                                  _expandedTileId = item.id;
                                }
                              });
                            },
                            onOpen: () {
                              if (_openDebtId != item.id) {
                                setState(() {
                                  _openDebtId = item.id;
                                });
                              }
                            },
                            onClose: () {
                              if (_openDebtId == item.id) {
                                setState(() {
                                  _openDebtId = null;
                                });
                              }
                            },
                            // Deletes straight away, with Undo.
                            onDelete: () {
                              final notifier =
                                  ref.read(debtsNotifierProvider.notifier);
                              final index = ref
                                  .read(debtsNotifierProvider)
                                  .debts
                                  .indexWhere((d) => d.id == item.id);
                              deleteWithUndo(
                                context,
                                label: 'Debt with ${item.personName}',
                                delete: () => notifier.deleteDebt(item.id),
                                restore: () =>
                                    notifier.restoreDebt(item, index),
                              );
                            },
                            onEdit: () {
                              EditDebtDialog.show(
                                context,
                                debt: item,
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

  Widget _buildFilterPill({required String label}) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        ref.read(debtsNotifierProvider.notifier).updateFilter(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'All',
          child: Text('All', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'I Owe',
          child: Text('I owe', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'Owed to me',
          child: Text('Owed to me', style: TextStyle(color: Colors.white)),
        ),
      ],
      offset: const Offset(0, 40),
      color: ZenioColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // 7pt of invisible padding above and below makes the tap target 48pt;
      // the space around the pill row is reduced by the same amount.
      child: Padding(
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
                label == 'Debts' ? 'All' : label,
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
      ),
    );
  }
}
