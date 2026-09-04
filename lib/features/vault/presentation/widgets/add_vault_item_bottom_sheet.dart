import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/vault/controller/vault/vault_notifier.dart';
import 'package:zenio/features/vault/controller/vault/vault_state.dart';
import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';

class AddVaultItemBottomSheet extends ConsumerStatefulWidget {
  final VaultMode mode;
  const AddVaultItemBottomSheet({required this.mode, super.key});

  static Future<void> show(BuildContext context, VaultMode mode) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddVaultItemBottomSheet(mode: mode),
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
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    if (_currentMode == VaultMode.cards) {
      final type = _cardTypeController.text.trim();
      final number = _cardNumberController.text.trim();
      final expiry = _expiryController.text.trim();
      final cvv = _cvvController.text.trim();

      if (type.isEmpty || number.isEmpty || expiry.isEmpty || cvv.isEmpty) {
        return;
      }

      final card = VaultCardModel(
        id: id,
        cardType: type,
        cardNumber: number,
        expiry: expiry,
        cvv: cvv,
      );
      ref.read(vaultNotifierProvider.notifier).addCard(card);
    } else {
      final content = _noteContentController.text.trim();
      if (content.isEmpty) return;

      final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);
      final note = VaultNoteModel(
        id: id,
        date: formattedDate,
        content: content,
      );
      ref.read(vaultNotifierProvider.notifier).addNote(note);
    }

    Navigator.of(context).pop();
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
            color: isSelected ? const Color(0xFFF2F2F2) : Colors.transparent,
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
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111111),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCard = _currentMode == VaultMode.cards;
    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);

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
              _buildTextField(_cardNumberController, 'Card Number',
                  keyboardType: TextInputType.number),
              _buildTextField(_expiryController, 'Expiry (MM/YY)'),
              _buildTextField(_cvvController, 'CVV',
                  keyboardType: TextInputType.number),
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
            ],

            const SizedBox(height: 12),

            // Save Button
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
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
            // Extends white background behind keyboard — not visible, prevents dark gap
            SizedBox(height: bottomInset),
          ],
        ),
      ),
    );
  }
}
