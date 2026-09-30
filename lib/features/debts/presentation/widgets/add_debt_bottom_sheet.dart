import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/debts/controller/debts/debts_notifier.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/datetime.dart';
import 'package:zenio/shared/utils/formatters.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

enum DebtType { iOwe, owedToMe }

class AddDebtBottomSheet extends ConsumerStatefulWidget {
  const AddDebtBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: const AddDebtBottomSheet(),
      ),
    );
  }

  @override
  ConsumerState<AddDebtBottomSheet> createState() => _AddDebtBottomSheetState();
}

class _AddDebtBottomSheetState extends ConsumerState<AddDebtBottomSheet> {
  DebtType _selectedType = DebtType.iOwe;

  late TextEditingController _amountController;
  late TextEditingController _personNameController;
  late TextEditingController _noteController;
  late FocusNode _personNameFocusNode;

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  /// Why the debt could not be saved, shown above the button.
  String? _formError;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _personNameController = TextEditingController();
    _noteController = TextEditingController();
    _personNameFocusNode = FocusNode();
    _personNameFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _personNameController.dispose();
    _noteController.dispose();
    _personNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final canSave =
        AppNumberFormat.parseAmount(_amountController.text) > 0 &&
            _personNameController.text.trim().isNotEmpty;

    final debtsState = ref.watch(debtsNotifierProvider);
    final existingNames = debtsState.debts
        .map((d) => d.personName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final query = _personNameController.text.trim().toLowerCase();
    final matchingSuggestions = existingNames.where((name) {
      final lower = name.toLowerCase();
      return query.isNotEmpty && lower.contains(query) && lower != query;
    }).toList();

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

            // Segmented Mode Switcher (I Owe, Owed To Me)
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
                children: [
                  _buildTabItem(
                    type: DebtType.iOwe,
                    label: 'I owe',
                    activeColor: ZenioColors.danger,
                  ),
                  _buildTabItem(
                    type: DebtType.owedToMe,
                    label: 'Owed to me',
                    activeColor: ZenioColors.primary,
                  ),
                ],
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
                      // Like Add transaction: the amount comes first.
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        ThousandsSeparatorInputFormatter(),
                      ],
                      onChanged: (val) {
                        setState(() => _formError = null);
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
            
            // Person Name Input Field with Suggestions
            Container(
              decoration: BoxDecoration(
                color: ZenioColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    child: TextField(
                      controller: _personNameController,
                      focusNode: _personNameFocusNode,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() => _formError = null),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ZenioColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Person Name',
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
                  if (matchingSuggestions.isNotEmpty &&
                      _personNameFocusNode.hasFocus) ...[
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE5E5EA),
                      indent: 20,
                      endIndent: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: matchingSuggestions.map((name) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _personNameController.text = name;
                                    _personNameController.selection =
                                        TextSelection.fromPosition(
                                      TextPosition(offset: name.length),
                                    );
                                  });
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.person_outline_rounded,
                                        size: 14,
                                        color: ZenioColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: ZenioColors.textPrimary,
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
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            
            // Note Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: ZenioColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _noteController,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: ZenioColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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

            // Date Selector
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
                        DateTimeUtils.displayDate(_selectedDate),
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
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  _formError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ZenioColors.danger,
                  ),
                ),
              ),

            // Save Debt Button
            SizedBox(
              height: 60,
              child: ElevatedButton(
                // Like Add transaction: ready once there is an amount and a
                // name.
                onPressed: _isSaving || !canSave
                    ? null
                    : () async {
                  final amount = AppNumberFormat.parseAmount(_amountController.text);
                  final personName = _personNameController.text.trim();
                  final note = _noteController.text.trim();

                  if (amount <= 0 || personName.isEmpty) {
                    setState(() {
                      _formError = amount <= 0
                          ? 'Enter an amount above 0'
                          : 'Enter who this debt is with';
                    });
                    return;
                  }

                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  final isOwed = _selectedType == DebtType.iOwe;

                  final debt = DebtModel(
                    id: id,
                    personName: personName,
                    date: formattedDate,
                    amount: amount,
                    currency: ref.read(currencyCodeProvider),
                    isOwed: isOwed,
                    iconName: isOwed ? 'down_arrow' : 'up_arrow',
                    note: note.isNotEmpty ? note : null,
                  );

                  final navigator = Navigator.of(context);
                  setState(() {
                    _isSaving = true;
                    _formError = null;
                  });
                  try {
                    await ref.read(debtsNotifierProvider.notifier).addDebt(debt);
                  } catch (_) {
                    if (!mounted) return;
                    setState(() {
                      _isSaving = false;
                      _formError = "Couldn't save the debt. Please try again.";
                    });
                    return;
                  }
                  // The form may have been closed (or the Vault locked) meanwhile.
                  if (!context.mounted) return;
                  unawaited(HapticFeedback.lightImpact());
                  ZenioSnackBar.show(
                    context,
                    message: isOwed
                        ? 'Saved · You owe $personName'
                        : 'Saved · $personName owes you',
                    type: ZenioSnackBarType.success,
                  );
                  navigator.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZenioColors.primary,
                  disabledBackgroundColor: const Color(0xFFE5E5EA),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isSaving || !canSave
                        ? ZenioColors.textSecondary
                        : Colors.white,
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

  Widget _buildTabItem({
    required DebtType type,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
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
                color: isSelected ? activeColor : const Color(0xFF808080),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
