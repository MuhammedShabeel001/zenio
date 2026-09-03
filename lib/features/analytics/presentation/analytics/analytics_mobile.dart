import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
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

class _AnalyticsScreenMobileState extends ConsumerState<AnalyticsScreenMobile> {
  String? _expandedCategoryId;

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
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
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
                  const SizedBox(height: 20),

                  // Filter Dropdown Pills Row (Week v, This Week v)
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

            // Light Curved Content Sheet
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
                      ListView(
                        padding: const EdgeInsets.fromLTRB(10, 16, 10, 90),
                        children: [
                          // Donut Chart Centered
                          Center(
                            child: DonutChartWidget(categories: categories),
                          ),
                          const SizedBox(height: 10),

                          // Category Legend Grid
                          CategoryLegendWidget(categories: categories),
                          const SizedBox(height: 20),

                          // Top Spent Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Top Spent',
                                style: TextStyle(
                                  fontSize: 20,
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
                            ...categories.map((spend) {
                              final isExpanded =
                                  _expandedCategoryId == spend.id;
                              return TopSpentCard(
                                spend: spend,
                                isExpanded: isExpanded,
                                onTap: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedCategoryId = null;
                                    } else {
                                      _expandedCategoryId = spend.id;
                                    }
                                  });
                                },
                              );
                            }),
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
      offset: const Offset(0, 45),
      elevation: 8,
      onSelected: (value) {
        ref.read(analyticsNotifierProvider.notifier).updatePeriod(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'Daily',
          child: Text('Daily', style: TextStyle(color: Color(0xFFD1D1D6), fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuItem(
          value: 'Weekly',
          child: Text('Weekly', style: TextStyle(color: Color(0xFFD1D1D6), fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuItem(
          value: 'Monthly',
          child: Text('Monthly', style: TextStyle(color: Color(0xFFD1D1D6), fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuItem(
          value: 'Custom',
          child: Text('Custom', style: TextStyle(color: Color(0xFFD1D1D6), fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF313131), width: 1),
      ),
      child: _buildFilterPill(label: currentPeriod),
    );
  }

  Widget _buildTimeframePicker(String period, String timeframe) {
    if (period.toLowerCase() == 'custom') {
      return GestureDetector(
        onTap: () async {
          List<DateTime?> selectedDates = [];
          final picked = await showModalBottomSheet<List<DateTime?>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF1A1A1A),
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
                            color: const Color(0xFF313131),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Text(
                          'Select Date Range',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        CalendarDatePicker2(
                          config: CalendarDatePicker2Config(
                            calendarType: CalendarDatePicker2Type.range,
                            selectedDayHighlightColor: Colors.white,
                            selectedRangeHighlightColor: Colors.white.withOpacity(0.15),
                            selectedDayTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            dayTextStyle: const TextStyle(color: Colors.white),
                            disabledDayTextStyle: const TextStyle(color: Color(0xFF313131)),
                            yearTextStyle: const TextStyle(color: Colors.white),
                            monthTextStyle: const TextStyle(color: Colors.white),
                            controlsTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            weekdayLabelTextStyle: const TextStyle(color: Color(0xFFD1D1D6)),
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
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      side: const BorderSide(color: Color(0xFF313131)),
                                    ),
                                  ),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: selectedDates.length == 2 && selectedDates[0] != null && selectedDates[1] != null
                                      ? () => Navigator.pop(context, selectedDates)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    disabledBackgroundColor: Colors.white.withOpacity(0.3),
                                  ),
                                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
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
          if (picked != null && picked.length == 2 && picked[0] != null && picked[1] != null) {
            final start = DateFormat('dd MMM').format(picked[0]!);
            final end = DateFormat('dd MMM').format(picked[1]!);
            ref.read(analyticsNotifierProvider.notifier).updateTimeframe('$start - $end');
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
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      elevation: 8,
      constraints: const BoxConstraints(maxHeight: 250),
      onSelected: (value) {
        ref.read(analyticsNotifierProvider.notifier).updateTimeframe(value);
      },
      itemBuilder: (context) => options.map((opt) => PopupMenuItem(
        value: opt, 
        child: Text(opt, style: const TextStyle(color: Color(0xFFD1D1D6), fontSize: 14, fontWeight: FontWeight.w500)),
      )).toList(),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF313131), width: 1),
      ),
      child: _buildFilterPill(label: timeframe),
    );
  }
}
