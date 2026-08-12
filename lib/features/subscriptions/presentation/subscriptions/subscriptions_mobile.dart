import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/subscriptions/presentation/widgets/subscription_card.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/add_transaction_bottom_sheet.dart';

class SubscriptionsScreenMobile extends ConsumerStatefulWidget {
  const SubscriptionsScreenMobile({super.key});

  @override
  ConsumerState<SubscriptionsScreenMobile> createState() =>
      _SubscriptionsScreenMobileState();
}

class _SubscriptionsScreenMobileState
    extends ConsumerState<SubscriptionsScreenMobile> {
  String? _openSubscriptionId;
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
    final state = ref.watch(subscriptionsNotifierProvider);
    final totalBalance = state.totalBalance;
    final subscriptions = state.subscriptions;

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
                  const SizedBox(height: 16),

                  // Bottom Row: Filter Dropdown Pill (All v)
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
                      if (subscriptions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No subscriptions found',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                        )
                      else
                        ...subscriptions.map(
                          (item) => SubscriptionCard(
                            key: ValueKey(item.id),
                            subscription: item,
                            isOpen: _openSubscriptionId == item.id,
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
                              if (_openSubscriptionId != item.id) {
                                setState(() {
                                  _openSubscriptionId = item.id;
                                });
                              }
                            },
                            onClose: () {
                              if (_openSubscriptionId == item.id) {
                                setState(() {
                                  _openSubscriptionId = null;
                                });
                              }
                            },
                            onDelete: () {
                              ref
                                  .read(subscriptionsNotifierProvider.notifier)
                                  .deleteSubscription(item.id);
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
}
