import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/subscriptions/controller/categories/subscription_categories_notifier.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/transactions/domain/models/category_item_model.dart';

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
      text: amount == amount.toInt() ? amount.toInt().toString() : amount.toString(),
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
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveChanges() {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    if (title.isEmpty) return;

    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) return;

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

    ref.read(subscriptionsNotifierProvider.notifier).updateSubscription(updatedSub);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);
    final categories = ref.watch(subscriptionCategoriesNotifierProvider);

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
                      color: Color(0xFF111111),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F2),
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
                                ? const Color(0xFFF2F2F2)
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
                                    ? const Color(0xFF111111)
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
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
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

              // Subscription Title Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Subscription Title',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF9E9EA5),
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
                  color: const Color(0xFFF2F2F2),
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
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF10B981)
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
                                        : const Color(0xFF111111),
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
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: Color(0xFF8E8E93),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ),
                      const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Save Changes Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
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
