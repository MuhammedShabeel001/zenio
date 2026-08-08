import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/analytics/controller/analytics/analytics_notifier.dart';
import 'package:zenio/features/analytics/presentation/widgets/category_legend_widget.dart';
import 'package:zenio/features/analytics/presentation/widgets/donut_chart_widget.dart';
import 'package:zenio/features/analytics/presentation/widgets/top_spent_card.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/add_transaction_bottom_sheet.dart';
import 'package:zenio/shared/widgets/custom_navigation_bar.dart';

class AnalyticsScreenMobile extends ConsumerStatefulWidget {
  const AnalyticsScreenMobile({
    this.onTabSelected,
    super.key,
  });

  final ValueChanged<int>? onTabSelected;

  @override
  ConsumerState<AnalyticsScreenMobile> createState() =>
      _AnalyticsScreenMobileState();
}

class _AnalyticsScreenMobileState
    extends ConsumerState<AnalyticsScreenMobile> {
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
    final state = ref.watch(analyticsNotifierProvider);
    final totalBalance = state.totalBalance;
    final categories = state.categorySpends;

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
                  const SizedBox(height: 16),

                  // Filter Dropdown Pills Row (Week v, This Week v)
                  Row(
                    children: [
                      _buildFilterPill(label: state.selectedPeriod),
                      const SizedBox(width: 10),
                      _buildFilterPill(label: state.selectedTimeframe),
                    ],
                  ),
                ],
              ),
            ),

            // Light Curved Content Sheet
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
                      ListView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
                        children: [
                          // Donut Chart Centered
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: DonutChartWidget(categories: categories),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Category Legend Grid
                          CategoryLegendWidget(categories: categories),
                          const SizedBox(height: 28),

                          // Top Spent Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Top Spent',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111111),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Assets.icons.rightArrow.svg(
                                width: 22,
                                height: 22,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF2CC56F),
                                  BlendMode.srcIn,
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

                          // Top Spent List
                          if (categories.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No spends recorded',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...categories
                                .take(2)
                                .map((spend) => TopSpentCard(spend: spend)),
                        ],
                      ),

                      // Floating Navigation Bar (Selected Index = 2)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: CustomNavigationBar(
                          selectedIndex: 2,
                          onTabSelected: (index) {
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
