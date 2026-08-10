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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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

                      // + Add Button Pill
                      GestureDetector(
                        onTap: () {
                          AddTransactionBottomSheet.show(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 14,
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
                    top: Radius.circular(36),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD1D1D6),
            ),
          ),
          const SizedBox(width: 8),
          Assets.icons.dropDown.svg(
            width: 14,
            height: 14,
            colorFilter: const ColorFilter.mode(
              Color(0xFF8E8E93),
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
