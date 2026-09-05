import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/subscriptions/controller/categories/subscription_categories_notifier.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/transactions/domain/models/category_item_model.dart';
import 'package:zenio/features/transactions/presentation/widgets/manage_categories_bottom_sheet.dart';

class AddSubscriptionBottomSheet extends ConsumerStatefulWidget {
  const AddSubscriptionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSubscriptionBottomSheet(),
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
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveSubscription() {
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

    final sub = SubscriptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: categoryName,
      amount: amount,
      currency: 'INR',
      nextBillingDate: _selectedDate,
      billingCycle: _selectedBillingCycle,
      iconName: selectedCat.emoji,
    );

    ref.read(subscriptionsNotifierProvider.notifier).addSubscription(sub);
    Navigator.of(context).pop();
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
            color: isSelected ? const Color(0xFFF2F2F2) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF111111)
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

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                  color: const Color(0xFFD1D1D6),
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
                onChanged: (val) {
                  if (val.length > 1 && val.startsWith('0') && !val.startsWith('0.')) {
                    final newText = val.replaceFirst(RegExp(r'^0+'), '');
                    _amountController.value = TextEditingValue(
                      text: newText.isEmpty ? '0' : newText,
                      selection: TextSelection.collapsed(offset: newText.length),
                    );
                  }
                  setState(() {});
                },
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
                decoration: const InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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

            // Subscription Title Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111111),
                ),
                decoration: const InputDecoration(
                  hintText: 'Subscription Title (e.g. Netflix)',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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

            // Category Chips Section
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
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
                            color: Color(0xFF8E8E93),
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
                                  color: Color(0xFF10B981),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Manage',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
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
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF10B981)
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
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
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
            const SizedBox(height: 6),

            // Save Button
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _saveSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
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
            SizedBox(height: bottomInset),
          ],
        ),
      ),
    );
  }
}
