import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hancod_theme/hancod_theme.dart';
import 'package:zenio/features/split/controller/split/split_notifier.dart';
import 'package:zenio/features/split/controller/split/split_state.dart';
import 'package:zenio/features/split/domain/models/split_calculation_model.dart';
import 'package:zenio/features/split/domain/services/split_share_service.dart';
import 'package:zenio/shared/shared.dart';
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
    // The split is kept between visits, so show the amount the results are
    // based on instead of an empty field.
    _billAmountController = TextEditingController(
      text: _amountText(ref.read(splitNotifierProvider).billAmount),
    );
  }

  static String _amountText(double amount) {
    if (amount == 0) return '';
    return amount == amount.truncateToDouble()
        ? amount.toInt().toString()
        : amount.toString();
  }

  @override
  void dispose() {
    _billAmountController.dispose();
    super.dispose();
  }

  String _formatCurrencyValue(double amount) {
    final symbol = ref.read(currencySymbolProvider);
    return '$symbol ${AppNumberFormat.formatAmount(amount, alwaysShowDecimals: true)}';
  }

  Future<void> _handleShare(BuildContext buttonContext, SplitState state) async {
    if (state.billAmount <= 0) {
      Alert.showSnackBar(
        'Please enter a bill amount to share',
        type: SnackBarType.warning,
      );
      return;
    }

    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    await HapticFeedback.lightImpact();

    final symbol = ref.read(currencySymbolProvider);
    await SplitShareService.share(
      state: state,
      currencySymbol: symbol,
      sharePositionOrigin: origin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(splitNotifierProvider);
    final notifier = ref.read(splitNotifierProvider.notifier);
    final currencySymbol = ref.watch(currencySymbolProvider);

    ref.listen(splitNotifierProvider, (previous, next) {
      if (previous?.billAmount != next.billAmount) {
        final parsed = double.tryParse(_billAmountController.text) ?? 0.0;
        if (parsed != next.billAmount) {
          // Update controller if the state changed externally (e.g. from loading saved data)
          _billAmountController.text = _amountText(next.billAmount);
        }
      }
    });

    final isEqualMode = state.mode == SplitMode.equal;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
          children: [
            const ScreenTitleBar(title: 'Split a bill'),
            // Dark Header Section (Bill Amount Input)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bill Amount TextField
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$currencySymbol ',
                        style: AppFonts.numeric(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _billAmountController,
                          // Only jump into the keyboard when there is nothing
                          // to look at yet.
                          autofocus: state.billAmount == 0,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          style: AppFonts.numeric(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          onChanged: (val) {
                            if (val.length > 1 && val.startsWith('0') && !val.startsWith('0.')) {
                              final newText = val.replaceFirst(RegExp(r'^0+'), '');
                              _billAmountController.value = TextEditingValue(
                                text: newText.isEmpty ? '0' : newText,
                                selection: TextSelection.collapsed(offset: newText.length),
                              );
                              final parsed = double.tryParse(newText) ?? 0.0;
                              notifier.setBillAmount(parsed);
                              return;
                            }
                            final parsed = double.tryParse(val) ?? 0.0;
                            notifier.setBillAmount(parsed);
                          },
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: AppFonts.numeric(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF808080),
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

                          // Form Card 1: How many people?
                          _buildCounterCard(
                            iconWidget: Assets.icons.group.svg(
                              width: 24,
                              height: 24,
                              colorFilter: const ColorFilter.mode(
                                ZenioColors.textPrimary,
                                BlendMode.srcIn,
                              ),
                            ),
                            title: 'How many people?',
                            count: state.peopleCount,
                            onDecrement: notifier.decrementPeople,
                            onIncrement: notifier.incrementPeople,
                          ),
                          const SizedBox(height: 12),

                          // Form Card 2: Coming back (Trip split mode only),
                          // easing in and out as the mode changes.
                          AnimatedSize(
                            duration:
                                ZenioMotion.of(context, ZenioMotion.standard),
                            curve: ZenioMotion.standardCurve,
                            alignment: Alignment.topCenter,
                            child: isEqualMode
                                ? const SizedBox(width: double.infinity)
                                : Column(
                                    children: [
                                      _buildCounterCard(
                                        iconWidget: const Icon(
                                          Icons.replay_rounded,
                                          size: 24,
                                          color: ZenioColors.textPrimary,
                                        ),
                                        title: 'Coming back',
                                        count: state.returnersCount,
                                        onDecrement: notifier.decrementReturners,
                                        onIncrement: notifier.incrementReturners,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                          ),

                          const SizedBox(height: 16),

                          // Info Note Text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: ZenioColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isEqualMode
                                      ? 'Equal split divides the amount equally between everyone.'
                                      : 'Trip split halves the bill: one half is shared by everyone going, the other by those coming back.',
                                  textAlign: TextAlign.center,
                                  // Readable size and contrast: it is the only
                                  // explanation of how the split works.
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: ZenioColors.textSecondary,
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
                                // Grows with larger text instead of clipping.
                                constraints:
                                    const BoxConstraints(minHeight: 80),
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
                            Builder(
                              builder: (buttonContext) {
                                return Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: Semantics(
                                    button: true,
                                    label: 'Share split',
                                    child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => _handleShare(buttonContext, state),
                                    child: SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: Center(
                                        child: Assets.icons.share.svg(
                                          width: 28,
                                          height: 28,
                                          colorFilter: const ColorFilter.mode(
                                            ZenioColors.primary,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ),
                                );
                              },
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
            Semantics(
              button: true,
              label: 'Decrease $title',
              child: GestureDetector(
              onTap: onDecrement,
              behavior: HitTestBehavior.opaque,
              // A 44dp touch area around the 36dp circle.
              child: Padding(
              padding: const EdgeInsets.all(4),
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
            ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                count.toString(),
                style: AppFonts.numeric(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF000000),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Increase $title',
              child: GestureDetector(
              onTap: onIncrement,
              behavior: HitTestBehavior.opaque,
              // A 44dp touch area around the 36dp circle.
              child: Padding(
              padding: const EdgeInsets.all(4),
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
            ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEqualSummaryContent({
    required double eachPersonPay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Each person pays',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: ZenioColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _formatCurrencyValue(eachPersonPay),
          style: AppFonts.numeric(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ZenioColors.textPrimary,
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
                  color: ZenioColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrencyValue(oneWayPay),
                style: AppFonts.numeric(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ZenioColors.textPrimary,
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
                  color: ZenioColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrencyValue(returnersPay),
                style: AppFonts.numeric(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ZenioColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
