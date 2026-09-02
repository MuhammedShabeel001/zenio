import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/split/controller/split/split_notifier.dart';
import 'package:zenio/features/split/domain/models/split_calculation_model.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class SplitScreenMobile extends ConsumerStatefulWidget {
  const SplitScreenMobile({super.key});

  @override
  ConsumerState<SplitScreenMobile> createState() => _SplitScreenMobileState();
}

class _SplitScreenMobileState extends ConsumerState<SplitScreenMobile> {
  late TextEditingController _billAmountController;

  @override
  void initState() {
    super.initState();
    _billAmountController = TextEditingController();
  }

  @override
  void dispose() {
    _billAmountController.dispose();
    super.dispose();
  }

  String _formatWholePart(double amount) {
    final whole = amount.toInt();
    final formatter = NumberFormat('#,##0');
    return formatter.format(whole);
  }

  String _formatDecimalPart(double amount) {
    final decimal = ((amount - amount.toInt()).abs() * 100).round();
    return '.${decimal.toString().padLeft(2, '0')}';
  }

  String _formatCurrencyValue(double amount) {
    return '₹ ${NumberFormat('#,##0.00').format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(splitNotifierProvider);
    final notifier = ref.read(splitNotifierProvider.notifier);

    ref.listen(splitNotifierProvider, (previous, next) {
      if (previous?.billAmount != next.billAmount) {
        final parsed = double.tryParse(_billAmountController.text) ?? 0.0;
        if (parsed != next.billAmount) {
          // Update controller if the state changed externally (e.g. from loading saved data)
          if (next.billAmount == 0) {
            _billAmountController.text = '';
          } else {
            // Check if it's an integer to remove trailing .0 if needed
            _billAmountController.text = next.billAmount == next.billAmount.toInt()
                ? next.billAmount.toInt().toString()
                : next.billAmount.toString();
          }
        }
      }
    });

    final isEqualMode = state.mode == SplitMode.equal;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Dark Header Section (Bill Amount Input)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bill Amount TextField
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '₹ ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _billAmountController,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val) ?? 0.0;
                            notifier.setBillAmount(parsed);
                          },
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF808080),
                              letterSpacing: -0.5,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter bill amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7A7A80),
                    ),
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
                  child: Stack(
                    children: [
                      // Scrollable Form Content
                      ListView(
                        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                        children: [
                          // Top Mode Switcher Pill (Equal split v / Trip split v)
                          Center(
                            child: _buildModePickerPill(
                              currentMode: state.mode,
                              onModeSelected: notifier.setMode,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Form Card 1: How many people ?
                          _buildCounterCard(
                            iconWidget: Assets.icons.group.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF111111),
                                BlendMode.srcIn,
                              ),
                            ),
                            title: 'How many people ?',
                            count: state.peopleCount,
                            onDecrement: notifier.decrementPeople,
                            onIncrement: notifier.incrementPeople,
                          ),
                          const SizedBox(height: 12),

                          // Form Card 2: Coming back (Trip split mode only)
                          if (!isEqualMode) ...[
                            _buildCounterCard(
                              iconWidget: const Icon(
                                Icons.replay_rounded,
                                size: 24,
                                color: Color(0xFF111111),
                              ),
                              title: 'Coming back',
                              count: state.returnersCount,
                              onDecrement: notifier.decrementReturners,
                              onIncrement: notifier.incrementReturners,
                            ),
                            const SizedBox(height: 12),
                          ],

                          const SizedBox(height: 16),

                          // Info Note Text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: Color(0xFF9E9EA5),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isEqualMode
                                      ? 'Standard split divides the amount equally.'
                                      : 'Trip split divides the bill into two halves: one for going and one for returning.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF9E9EA5),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Bottom Floating Fixed Summary & Action Bar
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 24,
                        child: Row(
                          children: [
                            // Summary Capsule Card
                            Expanded(
                              child: Container(
                                height: 80,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: isEqualMode
                                    ? _buildEqualSummaryContent(
                                        eachPersonPay: state.eachPersonPay,
                                      )
                                    : _buildTripSummaryContent(
                                        oneWayPay: state.oneWayPay,
                                        returnersPay: state.returnersPay,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 2),

                            // Green Circular Share Action Button
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Assets.icons.share.svg(
                                  width: 28,
                                  height: 28,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF10B981),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildModePickerPill({
    required SplitMode currentMode,
    required ValueChanged<SplitMode> onModeSelected,
  }) {
    final labelText =
        currentMode == SplitMode.equal ? 'Equal split' : 'Trip split';

    return PopupMenuButton<SplitMode>(
      onSelected: onModeSelected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFF1A1A1A),
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: SplitMode.equal,
          child: Text(
            'Equal split',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        const PopupMenuItem(
          value: SplitMode.trip,
          child: Text(
            'Trip split',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
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
              labelText,
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

  Widget _buildCounterCard({
    required Widget iconWidget,
    required String title,
    required int count,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      children: [
        // Circle Icon Badge
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            shape: BoxShape.circle,
          ),
          child: Center(child: iconWidget),
        ),
        const SizedBox(width: 16),

        // Title
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF000000),
            ),
          ),
        ),

        // Counter Controls (- count +)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onDecrement,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFD9D9D9), width: 1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.remove,
                    size: 24,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000000),
                ),
              ),
            ),
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFD9D9D9), width: 1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    size: 24,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEqualSummaryContent({required double eachPersonPay}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Each person pay',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF9E9EA5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _formatCurrencyValue(eachPersonPay),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111111),
          ),
        ),
      ],
    );
  }

  Widget _buildTripSummaryContent({
    required double oneWayPay,
    required double returnersPay,
  }) {
    return Row(
      children: [
        // Column 1: One-way
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'One-way',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9E9EA5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrencyValue(oneWayPay),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
        ),

        // Vertical Divider
        Container(
          width: 1,
          height: 36,
          color: const Color(0xFFEAEAEA),
        ),
        const SizedBox(width: 16),

        // Column 2: Returners
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Returners',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9E9EA5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrencyValue(returnersPay),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
