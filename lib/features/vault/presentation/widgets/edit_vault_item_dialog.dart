import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/vault/controller/vault/vault_notifier.dart';
import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';

enum EditVaultType { card, note }

class EditVaultItemDialog extends ConsumerStatefulWidget {
  const EditVaultItemDialog.card({
    required this.card,
    super.key,
  })  : type = EditVaultType.card,
        note = null;

  const EditVaultItemDialog.note({
    required this.note,
    super.key,
  })  : type = EditVaultType.note,
        card = null;

  final EditVaultType type;
  final VaultCardModel? card;
  final VaultNoteModel? note;

  static Future<void> showCard(
    BuildContext context, {
    required VaultCardModel card,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => EditVaultItemDialog.card(card: card),
    );
  }

  static Future<void> showNote(
    BuildContext context, {
    required VaultNoteModel note,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => EditVaultItemDialog.note(note: note),
    );
  }

  @override
  ConsumerState<EditVaultItemDialog> createState() => _EditVaultItemDialogState();
}

class _EditVaultItemDialogState extends ConsumerState<EditVaultItemDialog> {
  // Card controllers
  late TextEditingController _cardTypeController;
  late TextEditingController _cardNumberController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;

  // Note controllers
  late TextEditingController _noteContentController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.type == EditVaultType.card && widget.card != null) {
      _cardTypeController = TextEditingController(text: widget.card!.cardType);
      _cardNumberController = TextEditingController(text: widget.card!.cardNumber);
      _expiryController = TextEditingController(text: widget.card!.expiry);
      _cvvController = TextEditingController(text: widget.card!.cvv);
      _noteContentController = TextEditingController();
      _selectedDate = DateTime.now();
    } else {
      _cardTypeController = TextEditingController();
      _cardNumberController = TextEditingController();
      _expiryController = TextEditingController();
      _cvvController = TextEditingController();
      _noteContentController = TextEditingController(text: widget.note?.content ?? '');
      _selectedDate = DateTime.now();
      if (widget.note?.date != null && widget.note!.date.isNotEmpty) {
        try {
          _selectedDate = DateFormat('dd MMMM yyyy').parse(widget.note!.date);
        } catch (_) {}
      }
    }
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
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveChanges() {
    if (widget.type == EditVaultType.card) {
      final type = _cardTypeController.text.trim();
      final number = _cardNumberController.text.trim();
      final expiry = _expiryController.text.trim();
      final cvv = _cvvController.text.trim();

      if (type.isEmpty || number.isEmpty || expiry.isEmpty || cvv.isEmpty) return;

      final updatedCard = widget.card!.copyWith(
        cardType: type,
        cardNumber: number,
        expiry: expiry,
        cvv: cvv,
      );

      ref.read(vaultNotifierProvider.notifier).updateCard(updatedCard);
    } else {
      final content = _noteContentController.text.trim();
      if (content.isEmpty) return;

      final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);
      final updatedNote = widget.note!.copyWith(
        date: formattedDate,
        content: content,
      );

      ref.read(vaultNotifierProvider.notifier).updateNote(updatedNote);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isCard = widget.type == EditVaultType.card;
    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);

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
                  Text(
                    isCard ? 'Edit Card' : 'Edit Note',
                    style: const TextStyle(
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

              if (isCard) ...[
                // Card Type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _cardTypeController,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111111),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Card Type (e.g. Debit Card)',
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

                // Card Number
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111111),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Card Number',
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

                // Expiry & CVV Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _expiryController,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111111),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'MM/YY',
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
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111111),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'CVV',
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
                    ),
                  ],
                ),
              ] else ...[
                // Note Content Input
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _noteContentController,
                    maxLines: 5,
                    minLines: 3,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF111111),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Note content...',
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

                // Note Date Picker
                GestureDetector(
                  onTap: _pickDate,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
              ],
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
