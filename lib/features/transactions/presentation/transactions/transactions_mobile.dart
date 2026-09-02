import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/transactions/controller/transactions/transactions_notifier.dart';
import 'package:zenio/features/transactions/presentation/widgets/transaction_detail_card.dart';
import 'package:zenio/features/home/home.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/add_transaction_bottom_sheet.dart';

class TransactionsScreenMobile extends ConsumerStatefulWidget {
  const TransactionsScreenMobile({super.key});

  @override
  ConsumerState<TransactionsScreenMobile> createState() =>
      _TransactionsScreenMobileState();
}

class _TransactionsScreenMobileState
    extends ConsumerState<TransactionsScreenMobile> {
  String? _openTransactionId;
  String? _expandedTileId;
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
    final state = ref.watch(transactionsNotifierProvider);
    final totalBalance = state.totalBalance;
    final transactions = state.transactions;

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
                  // Top Row: Balance Display & + Add Button Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Balance
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
                          AddTransactionBottomSheet.show(context);
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

                  // Bottom Row: Filter Dropdown Pills
                  Row(
                    children: [
                      _buildPeriodPicker(state.selectedPeriod),
                      const SizedBox(width: 10),
                      _buildTimeframePicker(state.selectedPeriod, state.selectedTimeframe),
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
                      if (transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No transactions available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                        )
                      else
                        ...transactions.map(
                          (item) => TransactionDetailCard(
                            key: ValueKey(item.id),
                            transaction: item,
                            isOpen: _openTransactionId == item.id,
                            isTileExpanded: _expandedTileId == item.id,
                            note: item.note,
                            bankName: item.bankName,
                            timestamp: item.timestamp,
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
                            onDelete: () {
                              ref
                                  .read(transactionsNotifierProvider.notifier)
                                  .deleteTransaction(item.id);
                              ref
                                  .read(homeNotifierProvider.notifier)
                                  .deleteTransaction(item.id);
                            },
                            onEdit: () {
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
  Widget _buildPeriodPicker(String currentPeriod) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        ref.read(transactionsNotifierProvider.notifier).updatePeriod(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Daily', child: Text('Daily', style: TextStyle(color: Colors.white))),
        const PopupMenuItem(value: 'Weekly', child: Text('Weekly', style: TextStyle(color: Colors.white))),
        const PopupMenuItem(value: 'Monthly', child: Text('Monthly', style: TextStyle(color: Colors.white))),
        const PopupMenuItem(value: 'Custom', child: Text('Custom', style: TextStyle(color: Colors.white))),
      ],
      color: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: _buildFilterPill(label: currentPeriod),
    );
  }

  Widget _buildTimeframePicker(String period, String timeframe) {
    if (period.toLowerCase() == 'custom') {
      return GestureDetector(
        onTap: () async {
          final DateTimeRange? picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.white,
                    onPrimary: Colors.black,
                    surface: Color(0xFF1A1A1A),
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            final start = DateFormat('dd MMM').format(picked.start);
            final end = DateFormat('dd MMM').format(picked.end);
            ref.read(transactionsNotifierProvider.notifier).updateTimeframe('$start - $end');
          }
        },
        child: _buildFilterPill(label: timeframe),
      );
    }

    List<String> options = [];
    if (period.toLowerCase() == 'daily') {
      options = ['Today', 'Yesterday'];
    } else if (period.toLowerCase() == 'weekly') {
      options = ['This week', 'Past week'];
    } else if (period.toLowerCase() == 'monthly') {
      options = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
    }

    return PopupMenuButton<String>(
      onSelected: (value) {
        ref.read(transactionsNotifierProvider.notifier).updateTimeframe(value);
      },
      itemBuilder: (context) => options.map((opt) => PopupMenuItem(
        value: opt, 
        child: Text(opt, style: const TextStyle(color: Colors.white)),
      )).toList(),
      color: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: _buildFilterPill(label: timeframe),
    );
  }
}
