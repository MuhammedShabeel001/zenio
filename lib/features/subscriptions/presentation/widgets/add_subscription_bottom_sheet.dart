import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/subscriptions/controller/categories/subscription_categories_notifier.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/transactions/domain/models/category_item_model.dart';
import 'package:zenio/features/transactions/presentation/widgets/manage_categories_bottom_sheet.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/services/notification_service.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/formatters.dart';


class AddSubscriptionBottomSheet extends ConsumerStatefulWidget {
  const AddSubscriptionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: const AddSubscriptionBottomSheet(),
      ),
    );
  }

  @override
  ConsumerState<AddSubscriptionBottomSheet> createState() =>
      _AddSubscriptionBottomSheetState();
}

class _AddSubscriptionBottomSheetState
    extends ConsumerState<AddSubscriptionBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  String _selectedBillingCycle = 'Monthly';

  final List<String> _billingCycles = [
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.instrumentSansTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Why the subscription could not be saved, shown above the button.
  String? _formError;
  bool _isSaving = false;

  Future<void> _saveSubscription() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _formError = 'Enter the subscription name');
      return;
    }

    final amount = AppNumberFormat.parseAmount(_amountController.text);
    if (amount <= 0) {
      setState(() => _formError = 'Enter an amount above 0');
      return;
    }
    if (_formError != null) setState(() => _formError = null);

    final categories = ref.read(subscriptionCategoriesNotifierProvider);
    final selectedCat = categories.firstWhere(
      (c) => c.name == _selectedCategory,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : const CategoryItemModel(id: '', name: 'Subscription', emoji: '🏷️'),
    );
    final categoryName = _selectedCategory ??
        (categories.isNotEmpty ? categories.first.name : 'Subscription');

    final sub = SubscriptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: categoryName,
      amount: amount,
      currency: ref.read(currencyCodeProvider),
      nextBillingDate: _selectedDate,
      billingCycle: _selectedBillingCycle,
      iconName: selectedCat.emoji,
    );

    final navigator = Navigator.of(context);
    setState(() => _isSaving = true);
    try {
      await ref.read(subscriptionsNotifierProvider.notifier).addSubscription(sub);
    } catch (_) {
      if (!mounted) return;
      // Shown in the form: a snackbar would appear behind it.
      setState(() => _isSaving = false);
      setState(() => _formError = "Couldn't save the subscription. Please try again.");
      return;
    }
    // The form may have been closed (or the Vault locked) meanwhile.
    if (!mounted) return;
    navigator.pop();
    // Ask for notifications now, when the reason is obvious: renewal
    // reminders for this subscription.
    unawaited(ref.read(notificationServiceProvider).requestPermissions());
  }

  Widget _buildTabItem({
    required String cycle,
    required String label,
  }) {
    final isSelected = _selectedBillingCycle == cycle;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedBillingCycle = cycle;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? ZenioColors.fieldFill : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? ZenioColors.textPrimary
                    : const Color(0xFF808080),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(subscriptionCategoriesNotifierProvider);
    final formattedDate =
        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);
    final currencySymbol = ref.watch(currencySymbolProvider);


    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle Indicator
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: ZenioColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 26),

            // Segmented Billing Cycle Switcher (Weekly, Monthly, Yearly)
            Container(
              height: 60,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFCCCCCC),
                ),
              ),
              child: Row(
                children: _billingCycles
                    .map(
                      (cycle) => _buildTabItem(
                        cycle: cycle,
                        label: cycle,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Amount Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: ZenioColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    '$currencySymbol ',
                    style: AppFonts.numeric(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ZenioColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        ThousandsSeparatorInputFormatter(),
                      ],
                      onChanged: (val) {
                        setState(() {});
                      },
                      style: AppFonts.numeric(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ZenioColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: AppFonts.numeric(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ZenioColors.textPlaceholder,
                        ),
                        isDense: true,
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Subscription Title Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: ZenioColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ZenioColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Subscription Title (e.g. Netflix)',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ZenioColors.textPlaceholder,
                  ),
                  isDense: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Category Chips Section
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: ZenioColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: ZenioColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final picked =
                                await ManageCategoriesBottomSheet.show(
                              context,
                              isSubscription: true,
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedCategory = picked.name;
                              });
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 14,
                                  color: ZenioColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Manage',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: ZenioColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat.name ||
                            (_selectedCategory == null &&
                                cat == categories.first);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat.name;
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: ZenioMotion.fast,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ZenioColors.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    Text(
                                      cat.emoji,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : ZenioColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Date Selector (Next Billing Date)
            GestureDetector(
              onTap: _pickDate,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: ZenioColors.fieldFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: ZenioColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: AppFonts.numeric(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ),
                    const Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ZenioColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            if (_formError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _formError!,
                  style: const TextStyle(fontSize: 12, color: ZenioColors.danger),
                ),
              ),
            // Save Button
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZenioColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Save subscription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Extends white background behind keyboard
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
