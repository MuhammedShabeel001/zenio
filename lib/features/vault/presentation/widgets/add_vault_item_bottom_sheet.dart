import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/vault/controller/vault/vault_notifier.dart';
import 'package:zenio/features/vault/controller/vault/vault_state.dart';
import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';
import 'package:zenio/features/vault/domain/repositories/implementations/vault_repository.dart';
import 'package:zenio/features/vault/domain/vault_card_validation.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/datetime.dart';
import 'package:zenio/shared/utils/formatters.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

class AddVaultItemBottomSheet extends ConsumerStatefulWidget {
  final VaultMode mode;
  const AddVaultItemBottomSheet({required this.mode, super.key});

  static Future<void> show(BuildContext context, VaultMode mode) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: AddVaultItemBottomSheet(mode: mode),
      ),
    );
  }

  @override
  ConsumerState<AddVaultItemBottomSheet> createState() =>
      _AddVaultItemBottomSheetState();
}

class _AddVaultItemBottomSheetState
    extends ConsumerState<AddVaultItemBottomSheet> {
  late VaultMode _currentMode;

  // Card fields
  late TextEditingController _cardTypeController;
  late TextEditingController _cardNumberController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;

  // Note fields
  late TextEditingController _noteContentController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;

    _cardTypeController = TextEditingController();
    _cardNumberController = TextEditingController();
    _expiryController = TextEditingController();
    _cvvController = TextEditingController();
    _noteContentController = TextEditingController();
  }

  @override
  void dispose() {
    _cardTypeController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _noteContentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  bool _isSaving = false;

  /// Why the item could not be saved, shown above the button.
  String? _formError;

  Future<void> _save() async {
    if (_isSaving) return;
    late Future<void> Function() save;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    if (_currentMode == VaultMode.cards) {
      final type = _cardTypeController.text.trim();
      final number = _cardNumberController.text.trim();
      final expiry = _expiryController.text.trim();
      final cvv = _cvvController.text.trim();

      final problem = validateVaultCard(
        type: type,
        number: number,
        expiry: expiry,
        cvv: cvv,
      );
      if (problem != null) {
        setState(() => _formError = problem);
        return;
      }

      final card = VaultCardModel(
        id: id,
        cardType: type,
        cardNumber: number,
        expiry: expiry,
        cvv: cvv,
      );
      save = () => ref.read(vaultNotifierProvider.notifier).addCard(card);
    } else {
      final content = _noteContentController.text.trim();
      if (content.isEmpty) {
        setState(() => _formError = 'Write something to save');
        return;
      }

      final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);
      final note = VaultNoteModel(
        id: id,
        date: formattedDate,
        content: content,
      );
      save = () => ref.read(vaultNotifierProvider.notifier).addNote(note);
    }

    final navigator = Navigator.of(context);
    setState(() {
      _isSaving = true;
      _formError = null;
    });
    try {
      await save();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _formError = e is VaultUnavailableException
            ? e.toString()
            : "Couldn't save. Please try again.";
      });
      return;
    }
    // The form may have been closed (or the Vault locked) meanwhile.
    if (!mounted) return;
    // Show the kind of item just saved, so a new note is not hidden behind
    // the card list (and the other way round).
    ref.read(vaultNotifierProvider.notifier).setMode(_currentMode);
    unawaited(HapticFeedback.lightImpact());
    ZenioSnackBar.show(
      context,
      message: _currentMode == VaultMode.cards ? 'Card saved' : 'Note saved',
      type: ZenioSnackBarType.success,
    );
    navigator.pop();
  }

  Widget _buildTabItem({
    required VaultMode type,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _currentMode == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentMode = type;
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

  Widget _buildTextField(
    TextEditingController controller,
    String hintText, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int minLines = 1,
    int maxLines = 1,
    bool isNumeric = false,
    bool obscureText = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(
        color: ZenioColors.fieldFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        enableSuggestions: !obscureText,
        autocorrect: !obscureText,
        minLines: minLines,
        maxLines: maxLines,
        style: isNumeric
            ? AppFonts.numeric(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ZenioColors.textPrimary,
              )
            : const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ZenioColors.textPrimary,
              ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: isNumeric
              ? AppFonts.numeric(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ZenioColors.textPlaceholder,
                )
              : const TextStyle(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCard = _currentMode == VaultMode.cards;


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

            // Segmented Mode Switcher
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
                    type: VaultMode.cards,
                    label: 'Card',
                    activeColor: const Color(0xFF000000),
                  ),
                  _buildTabItem(
                    type: VaultMode.notes,
                    label: 'Note',
                    activeColor: const Color(0xFF000000),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (isCard) ...[
              _buildTextField(_cardTypeController, 'Card Type (e.g., Credit)'),
              _buildTextField(
                _cardNumberController,
                'Card Number',
                keyboardType: TextInputType.number,
                isNumeric: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19),
                ],
              ),
              _buildTextField(
                _expiryController,
                'Expiry (MM/YY)',
                keyboardType: TextInputType.datetime,
                isNumeric: true,
                inputFormatters: [
                  ExpiryDateInputFormatter(),
                ],
              ),
              _buildTextField(
                _cvvController,
                'CVV',
                keyboardType: TextInputType.number,
                isNumeric: true,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
            ] else ...[
              // Note Input Field
              _buildTextField(
                _noteContentController,
                'Add a note...',
                keyboardType: TextInputType.multiline,
                minLines: 4,
                maxLines: 8,
              ),

              // Date Selector
              GestureDetector(
                onTap: _pickDate,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 18),
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
            ],

            const SizedBox(height: 12),

            if (_formError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  _formError!,
                  style: const TextStyle(fontSize: 12, color: ZenioColors.danger),
                ),
              ),
            // Save Button
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZenioColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Save',
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
