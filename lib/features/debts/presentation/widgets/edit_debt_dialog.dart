import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/debts/controller/debts/debts_notifier.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/features/debts/presentation/widgets/add_debt_bottom_sheet.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/datetime.dart';
import 'package:zenio/shared/utils/formatters.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

class EditDebtDialog extends ConsumerStatefulWidget {
  const EditDebtDialog({
    required this.debt,
    super.key,
  });

  final DebtModel debt;

  static Future<void> show(
    BuildContext context, {
    required DebtModel debt,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => EditDebtDialog(debt: debt),
    );
  }

  @override
  ConsumerState<EditDebtDialog> createState() => _EditDebtDialogState();
}

class _EditDebtDialogState extends ConsumerState<EditDebtDialog> {
  late DebtType _selectedType;
  late TextEditingController _amountController;
  late TextEditingController _personNameController;
  late TextEditingController _noteController;
  late FocusNode _personNameFocusNode;

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _selectedType = d.isOwed ? DebtType.iOwe : DebtType.owedToMe;

    final amount = d.amount;
    _amountController = TextEditingController(
      text: AppNumberFormat.formatAmount(amount),
    );
    _personNameController = TextEditingController(text: d.personName);
    _noteController = TextEditingController(text: d.note ?? '');
    _personNameFocusNode = FocusNode();
    _personNameFocusNode.addListener(() {
      setState(() {});
    });

    _selectedDate = DateTime.now();
    if (d.date.isNotEmpty) {
      try {
        _selectedDate = DateFormat('dd MMMM yyyy').parse(d.date);
      } catch (_) {
        try {
          _selectedDate = DateFormat('dd-MM-yyyy').parse(d.date);
        } catch (_) {}
      }
    }
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

  bool _isSaving = false;

  /// Why the changes could not be saved, shown above the button.
  String? _formError;

  Future<void> _saveChanges() async {
    if (_isSaving) return;
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

    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);
    final isOwed = _selectedType == DebtType.iOwe;

    final updatedDebt = widget.debt.copyWith(
      personName: personName,
      date: formattedDate,
      amount: amount,
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
      await ref.read(debtsNotifierProvider.notifier).updateDebt(updatedDebt);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _formError = "Couldn't save your changes. Please try again.";
      });
      return;
    }
    // The form may have been closed (or the Vault locked) meanwhile.
    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    ZenioSnackBar.show(
      context,
      message: 'Debt saved · ${updatedDebt.personName}',
      type: ZenioSnackBarType.success,
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = ref.watch(currencySymbolProvider);

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
                    'Edit debt',
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

              // Mode Switcher (I Owe / Owed to me)
              Container(
                height: 52,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
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
                        horizontal: 24,
                        vertical: 15,
                      ),
                      child: TextField(
                        controller: _personNameController,
                        focusNode: _personNameFocusNode,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: ZenioColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Person Name',
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
                    if (matchingSuggestions.isNotEmpty &&
                        _personNameFocusNode.hasFocus) ...[
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE5E5EA),
                        indent: 16,
                        endIndent: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.person_outline_rounded,
                                          size: 14,
                                          color: ZenioColors.primary,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 12,
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

              // Note Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                decoration: BoxDecoration(
                  color: ZenioColors.fieldFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: 2,
                  minLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ZenioColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle: TextStyle(
                      fontSize: 14,
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

              // Date Picker Field
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
                          DateTimeUtils.displayDate(_selectedDate),
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: ZenioColors.danger,
                    ),
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
                    'Save changes',
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
            borderRadius: BorderRadius.circular(26),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
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
