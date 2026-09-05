import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';

class EditWalletBalanceBottomSheet extends ConsumerStatefulWidget {
  const EditWalletBalanceBottomSheet({
    required this.cardIndex,
    super.key,
  });

  final int cardIndex;

  static void show(BuildContext context, int cardIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditWalletBalanceBottomSheet(cardIndex: cardIndex),
    );
  }

  @override
  ConsumerState<EditWalletBalanceBottomSheet> createState() => _EditWalletBalanceBottomSheetState();
}

class _EditWalletBalanceBottomSheetState extends ConsumerState<EditWalletBalanceBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  String _mode = 'add'; // 'add', 'subtract', 'set'

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onSave() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;
    
    final amount = double.tryParse(amountText);
    if (amount == null) return;

    ref.read(walletNotifierProvider.notifier).updateCardBalance(widget.cardIndex, amount, mode: _mode);
    Navigator.of(context).pop();
  }

  Widget _buildModeButton(String modeValue, String label) {
    final isSelected = _mode == modeValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _mode = modeValue;
            _amountController.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Edit Balance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                _buildModeButton('add', 'Add (+)'),
                const SizedBox(width: 8),
                _buildModeButton('subtract', 'Subtract (-)'),
                const SizedBox(width: 8),
                _buildModeButton('set', 'Set (=)'),
              ],
            ),
            const SizedBox(height: 24),

            // Amount field
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                },
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: _mode == 'set' ? 'Enter exact balance' : 'Enter amount',
                  hintStyle: const TextStyle(
                    color: Color(0xFFA0A0A0),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                autofocus: true,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _mode == 'set' ? 'Set Balance' : (_mode == 'add' ? 'Add Funds' : 'Subtract Funds'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
