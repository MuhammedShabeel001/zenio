import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/subscriptions/controller/categories/subscription_categories_notifier.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/transactions/domain/models/category_item_model.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/formatters.dart';

class EditSubscriptionDialog extends ConsumerStatefulWidget {
  const EditSubscriptionDialog({
    required this.subscription,
    super.key,
  });

  final SubscriptionModel subscription;

  static Future<void> show(
    BuildContext context, {
    required SubscriptionModel subscription,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => EditSubscriptionDialog(subscription: subscription),
    );
  }

  @override
  ConsumerState<EditSubscriptionDialog> createState() =>
      _EditSubscriptionDialogState();
}

class _EditSubscriptionDialogState
    extends ConsumerState<EditSubscriptionDialog> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;

  late DateTime _selectedDate;
  String? _selectedCategory;
  late String _selectedBillingCycle;

  final List<String> _billingCycles = [
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;
    _titleController = TextEditingController(text: sub.title);
    final amount = sub.amount;
    _amountController = TextEditingController(
      text: AppNumberFormat.formatAmount(amount),
    );
    _selectedDate = sub.nextBillingDate;
    _selectedCategory = sub.category;
    _selectedBillingCycle = sub.billingCycle.isNotEmpty ? sub.billingCycle : 'Monthly';
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

  Future<void> _saveChanges() async {
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

    final updatedSub = widget.subscription.copyWith(
      title: title,
      category: categoryName,
      amount: amount,
      nextBillingDate: _selectedDate,
      billingCycle: _selectedBillingCycle,
      iconName: selectedCat.emoji,
    );

    final navigator = Navigator.of(context);
    setState(() => _isSaving = true);
    try {
      await ref
          .read(subscriptionsNotifierProvider.notifier)
          .updateSubscription(updatedSub);
    } catch (_) {
      if (!mounted) return;
      // Shown in the form: a snackbar would appear behind it.
      setState(() => _isSaving = false);
      setState(() => _formError = "Couldn't save your changes. Please try again.");
      return;
    }
    // The form may have been closed (or the Vault locked) meanwhile.
    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);
    final categories = ref.watch(subscriptionCategoriesNotifierProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Subscription',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ZenioColors.textPrimary,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Close',
                    excludeSemantics: true,
                    onTap: () => Navigator.of(context).pop(),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      // A 44dp touch area around the 32dp circle.
                      child: SizedBox.square(
                        dimension: 44,
                        child: Center(
                          child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: ZenioColors.fieldFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Billing Cycle Switcher (Weekly, Monthly, Yearly)
              Container(
                height: 52,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Row(
                  children: _billingCycles.map((cycle) {
                    final isSelected = _selectedBillingCycle.toLowerCase() ==
                        cycle.toLowerCase();
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
                            color: isSelected
                                ? ZenioColors.fieldFill
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Center(
                            child: Text(
                              cycle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w400,
                                color: isSelected
                                    ? ZenioColors.textPrimary
                                    : const Color(0xFF808080),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Amount Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
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

              // Subscription Title Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                decoration: BoxDecoration(
                  color: ZenioColors.fieldFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: ZenioColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Subscription Title',
                    hintStyle: TextStyle(
                      fontSize: 15,
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

              // Category Selector Chips
              Container(
                decoration: BoxDecoration(
                  color: ZenioColors.fieldFill,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat.name ||
                          (_selectedCategory == null && cat == categories.first);
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
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? ZenioColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  Text(cat.emoji, style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 12,
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
              ),
              const SizedBox(height: 8),

              // Billing Date Picker Field
              GestureDetector(
                onTap: _pickDate,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: ZenioColors.fieldFill,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: ZenioColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: AppFonts.numeric(
                            fontSize: 13,
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
              const SizedBox(height: 16),

              if (_formError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _formError!,
                    style: const TextStyle(fontSize: 12, color: ZenioColors.danger),
                  ),
                ),
              // Save Changes Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZenioColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
