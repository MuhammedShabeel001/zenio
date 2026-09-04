import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/debts/controller/debts/debts_notifier.dart';
import 'package:zenio/features/debts/presentation/widgets/debt_card.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/features/debts/presentation/widgets/add_debt_bottom_sheet.dart';
import 'package:zenio/features/debts/presentation/widgets/edit_debt_dialog.dart';

class DebtsScreenMobile extends ConsumerStatefulWidget {
  const DebtsScreenMobile({super.key});

  @override
  ConsumerState<DebtsScreenMobile> createState() => _DebtsScreenMobileState();
}

class _DebtsScreenMobileState extends ConsumerState<DebtsScreenMobile> {
  String? _openDebtId;
  String? _expandedTileId;
  String _formatWholePart(double amount) {
    final isNegative = amount < 0;
    final absWhole = amount.abs().toInt();
    final formatter = NumberFormat('#,##0');
    final formattedStr = formatter.format(absWhole);
    return isNegative ? '- $formattedStr' : formattedStr;
  }

  String _formatDecimalPart(double amount) {
    final decimal = ((amount - amount.toInt()).abs() * 100).round();
    return '.${decimal.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(debtsNotifierProvider);
    final debts = state.debts;

    final filteredDebts = debts.where((debt) {
      if (state.selectedFilter == 'I Owe') return debt.isOwed;
      if (state.selectedFilter == 'I Own') return !debt.isOwed;
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
            // Dark Top Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Balance Display & + Add Button Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Balance (₹ - 268.01)
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
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFF313131),
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
                  const SizedBox(height: 20),

                  // Bottom Row: Filter Dropdown Pill (Debts v)
                  Row(
                    children: [
                      _buildFilterPill(label: state.selectedFilter),
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(10, 16, 10, 20),
                    children: [
                      if (filteredDebts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No debts found',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                        )
                      else
                        ...filteredDebts.map(
                          (item) => DebtCard(
                            key: ValueKey(item.id),
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
                            onDelete: () {
                              ref
                                  .read(debtsNotifierProvider.notifier)
                                  .deleteDebt(item.id);
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
          child: Text('I Owe', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'I Own',
          child: Text('I Own', style: TextStyle(color: Colors.white)),
        ),
      ],
      offset: const Offset(0, 40),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
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
      ),
    );
  }
}
