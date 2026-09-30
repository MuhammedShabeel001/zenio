import 'package:flutter/material.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/shared/utils/period_filter.dart';
import 'package:zenio/features/analytics/controller/analytics/analytics_notifier.dart';
import 'package:zenio/features/analytics/presentation/categories/categories_list_screen.dart';
import 'package:zenio/features/analytics/presentation/widgets/category_legend_widget.dart';
import 'package:zenio/features/analytics/presentation/widgets/donut_chart_widget.dart';
import 'package:zenio/features/analytics/presentation/widgets/top_spent_card.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/shared/shared.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

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
  final ScrollController _scrollController = ScrollController();

  /// How far the legend has collapsed (0 to 1) as the list scrolls. Only the
  /// legend listens to it, so scrolling does not rebuild the whole screen.
  final ValueNotifier<double> _legendCollapse = ValueNotifier(0);
  String? _expandedCategoryId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _legendCollapse.dispose();
    super.dispose();
  }

  void _onScroll() {
    _legendCollapse.value = (_scrollController.offset / 60.0).clamp(0.0, 1.0);
  }

  String _formatWholePart(double amount) =>
      AppNumberFormat.formatWholePart(amount);

  String _formatDecimalPart(double amount) =>
      AppNumberFormat.formatDecimalPart(amount);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsNotifierProvider);
    final walletState = ref.watch(walletNotifierProvider);
    final walletCards = walletState.cards;
    final totalBalance = state.totalBalance;
    final categories = state.categorySpends.take(10).toList();
    final currencySymbol = ref.watch(currencySymbolProvider);

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
                  // Top Row: Total Balance on Left, Wallet Dropdown on Top Right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Balance
                      Flexible(
                        child: RichText(
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
                      ),
                      const SizedBox(width: 8),
                      _buildWalletPicker(state.selectedWallet, walletCards),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Filter Dropdown Pills Row (Period v, Timeframe v)
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          // Donut Chart Centered (Fixed / Pinned)
                          Center(
                            child: RepaintBoundary(
                              child: DonutChartWidget(categories: categories),
                            ),
                          ),

                          // Category legend that collapses while the list
                          // scrolls.
                          ValueListenableBuilder<double>(
                            valueListenable: _legendCollapse,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: CategoryLegendWidget(categories: categories),
                            ),
                            builder: (context, collapse, legend) {
                              final visible = 1.0 - collapse;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: 10 * visible),
                                  ClipRect(
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      heightFactor: visible,
                                      child: Opacity(
                                        opacity: visible,
                                        child: Transform.scale(
                                          scale: 1.0 - collapse * 0.2,
                                          alignment: Alignment.topCenter,
                                          child: legend,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16 * visible + 4),
                                ],
                              );
                            },
                          ),

                          // Top Spent Section Header (Fixed / Pinned)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (context) =>
                                            const CategoriesListScreen(),
                                      ),
                                    );
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Top Spent',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: ZenioColors.textPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'See All',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: ZenioColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Assets.icons.rightArrow.svg(
                                            width: 18,
                                            height: 18,
                                            colorFilter: const ColorFilter.mode(
                                              ZenioColors.primary,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(
                                  color: Color(0xFFECECEC),
                                  height: 1,
                                  thickness: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Categories List Only Scrolls!
                          Expanded(
                            child: categories.isEmpty
                                ? Center(
                                    child: SingleChildScrollView(
                                      child: state.status ==
                                                  AnalyticsStatus.loading ||
                                              state.status ==
                                                  AnalyticsStatus.initial
                                          ? const ListStateMessage.loading()
                                          : state.status == AnalyticsStatus.error
                                          ? ListStateMessage.error(
                                              onRetry: ref
                                                  .read(homeNotifierProvider
                                                      .notifier,)
                                                  .loadMoneyTrackerData,
                                            )
                                          : ListStateMessage(
                                              title: 'No spending in this period',
                                              message:
                                                  'Expenses you add will be grouped by category here.',
                                              icon: Icons.pie_chart_outline_rounded,
                                              actionLabel: 'Add transaction',
                                              onAction: () =>
                                                  AddTransactionBottomSheet.show(
                                                context,
                                              ),
                                            ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.fromLTRB(
                                      10,
                                      4,
                                      10,
                                      CustomNavigationBar.reservedHeight(context),
                                    ),
                                    itemCount: categories.length,
                                    itemBuilder: (context, index) {
                                      final spend = categories[index];
                                      final isExpanded =
                                          _expandedCategoryId == spend.id;
                                      return TopSpentCard(
                                        spend: spend,
                                        totalSpend: totalBalance,
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
                                    },
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

  Widget _buildFilterPill({
    required String label,
    Widget? leading,
    double? maxWidth,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 6),
          ],
          if (maxWidth != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ZenioColors.border,
                ),
              ),
            )
          else
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
    );
  }

  Widget _buildWalletPicker(String selectedWallet, List<WalletCardModel> cards) {
    final isAll = selectedWallet.trim().toLowerCase() == 'all wallets' ||
        selectedWallet.trim().toLowerCase() == 'all';
    final matchingCard = isAll
        ? null
        : cards.cast<WalletCardModel?>().firstWhere(
              (c) =>
                  c?.bankName.trim().toLowerCase() ==
                  selectedWallet.trim().toLowerCase(),
              orElse: () => null,
            );

    Widget leading;
    if (isAll || matchingCard == null) {
      leading = const Icon(
        Icons.account_balance_wallet_rounded,
        size: 15,
        color: ZenioColors.primary,
      );
    } else {
      Color startColor;
      Color endColor;
      try {
        var startHex = matchingCard.gradientStartHex.replaceAll('#', '').trim();
        var endHex = matchingCard.gradientEndHex.replaceAll('#', '').trim();
        if (startHex.length == 6) startHex = 'FF$startHex';
        if (endHex.length == 6) endHex = 'FF$endHex';
        startColor = Color(int.parse('0x$startHex'));
        endColor = Color(int.parse('0x$endHex'));
      } catch (_) {
        startColor = ZenioColors.primary;
        endColor = ZenioColors.primary;
      }
      leading = Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    final uniqueBankNames = cards
        .map((c) => c.bankName.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();

    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      elevation: 8,
      constraints: const BoxConstraints(maxHeight: 300),
      onSelected: (value) {
        ref.read(analyticsNotifierProvider.notifier).updateWallet(value);
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        final isAllSelected = isAll;
        items.add(
          PopupMenuItem<String>(
            value: 'All Wallets',
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 16,
                  color: ZenioColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All Wallets',
                    style: TextStyle(
                      color: isAllSelected ? Colors.white : ZenioColors.border,
                      fontSize: 14,
                      fontWeight:
                          isAllSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (isAllSelected)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: ZenioColors.primary,
                  ),
              ],
            ),
          ),
        );

        if (uniqueBankNames.isNotEmpty) {
          items.add(
            const PopupMenuDivider(height: 1),
          );

          for (final bank in uniqueBankNames) {
            final card = cards.cast<WalletCardModel?>().firstWhere(
                  (c) => c?.bankName.trim().toLowerCase() == bank.toLowerCase(),
                  orElse: () => null,
                );

            Color sColor = ZenioColors.primary;
            Color eColor = ZenioColors.primary;
            if (card != null) {
              try {
                var startHex = card.gradientStartHex.replaceAll('#', '').trim();
                var endHex = card.gradientEndHex.replaceAll('#', '').trim();
                if (startHex.length == 6) startHex = 'FF$startHex';
                if (endHex.length == 6) endHex = 'FF$endHex';
                sColor = Color(int.parse('0x$startHex'));
                eColor = Color(int.parse('0x$endHex'));
              } catch (_) {}
            }

            final isSelected =
                !isAll && selectedWallet.trim().toLowerCase() == bank.toLowerCase();

            items.add(
              PopupMenuItem<String>(
                value: bank,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [sColor, eColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bank,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : ZenioColors.border,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: ZenioColors.primary,
                      ),
                  ],
                ),
              ),
            );
          }
        }

        return items;
      },
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF313131), width: 1),
      ),
      child: _buildFilterPill(
        label: isAll ? 'All Wallets' : selectedWallet,
        leading: leading,
        maxWidth: 110,
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
          child: Text('Daily', style: TextStyle(color: ZenioColors.border, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuItem(
          value: 'Weekly',
          child: Text('Weekly', style: TextStyle(color: ZenioColors.border, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuItem(
          value: 'Monthly',
          child: Text('Monthly', style: TextStyle(color: ZenioColors.border, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuItem(
          value: 'Custom',
          child: Text('Custom', style: TextStyle(color: ZenioColors.border, fontSize: 14, fontWeight: FontWeight.w500)),
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
                            selectedDayTextStyle: AppFonts.numeric(color: Colors.black, fontWeight: FontWeight.bold),
                            dayTextStyle: AppFonts.numeric(color: Colors.white),
                            disabledDayTextStyle: AppFonts.numeric(color: const Color(0xFF313131)),
                            yearTextStyle: AppFonts.numeric(color: Colors.white),
                            monthTextStyle: const TextStyle(color: Colors.white),
                            controlsTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            weekdayLabelTextStyle: const TextStyle(color: ZenioColors.border),
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
            ref
                .read(analyticsNotifierProvider.notifier)
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
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
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
        child: Text(opt, style: const TextStyle(color: ZenioColors.border, fontSize: 14, fontWeight: FontWeight.w500)),
      ),).toList(),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF313131), width: 1),
      ),
      child: _buildFilterPill(label: timeframe),
    );
  }
}
