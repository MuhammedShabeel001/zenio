import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/shared/shared.dart';

/// Corrects a wallet's balance. The change is recorded as a balance
/// adjustment transaction, so it shows in the history and is not counted as
/// income or spending.
class AdjustBalanceBottomSheet extends ConsumerStatefulWidget {
  const AdjustBalanceBottomSheet({
    required this.cardIndex,
    super.key,
  });

  final int cardIndex;

  static void show(BuildContext context, int cardIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: AdjustBalanceBottomSheet(cardIndex: cardIndex),
      ),
    );
  }

  @override
  ConsumerState<AdjustBalanceBottomSheet> createState() =>
      _AdjustBalanceBottomSheetState();
}

class _AdjustBalanceBottomSheetState
    extends ConsumerState<AdjustBalanceBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  String _mode = 'add'; // 'add', 'subtract', 'set'

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool _isSaving = false;
  String? _saveError;

  Future<void> _onSave(WalletCardModel card) async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || amountText == '-' || _isSaving) return;

    final amount = AppNumberFormat.parseAmount(amountText);
    if (amount <= 0 && _mode != 'set') return;

    final target = switch (_mode) {
      'add' => card.balance + amount,
      'subtract' => card.balance - amount,
      _ => amount,
    };

    setState(() => _isSaving = true);
    try {
      await ref
          .read(walletNotifierProvider.notifier)
          .adjustBalance(card.id, target);
      await HapticFeedback.lightImpact();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      // Shown in the sheet: a snackbar would appear behind it.
      setState(() {
        _isSaving = false;
        _saveError = e is WalletNameConflictException
            ? e.message
            : "Couldn't adjust the balance. Please try again.";
      });
    }
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
            color: isSelected ? ZenioColors.primary : ZenioColors.fieldFill,
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
    final walletState = ref.watch(walletNotifierProvider);
    final card = widget.cardIndex < walletState.cards.length
        ? walletState.cards[widget.cardIndex]
        : null;
    final currencySymbol = ref.watch(currencySymbolProvider);

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
            const SizedBox(height: 20),

            Text(
              card == null ? 'Adjust balance' : 'Adjust ${card.bankName}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            if (card != null) ...[
              const SizedBox(height: 4),
              Text(
                'Current: $currencySymbol ${AppNumberFormat.formatAmount(card.balance, alwaysShowDecimals: true)}',
                style: AppFonts.numeric(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ZenioColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),

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
                color: ZenioColors.fieldFill,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '$currencySymbol ',
                    style: AppFonts.numeric(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                        signed: _mode == 'set',
                      ),
                      inputFormatters: [
                        // Only a balance to set can be below zero.
                        ThousandsSeparatorInputFormatter(
                          allowNegative: _mode == 'set',
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {});
                      },
                      style: AppFonts.numeric(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: _mode == 'set' ? '0.00' : '0',
                        hintStyle: AppFonts.numeric(
                          color: const Color(0xFFA0A0A0),
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
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _saveError!,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 12, color: ZenioColors.danger),
                ),
              ),
            const Text(
              'Saved as a balance adjustment in your history. It is not '
              'counted as income or spending.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF6E6E73)),
            ),
            const SizedBox(height: 16),

            // Save button
            ElevatedButton(
              onPressed: card == null || _isSaving ? null : () => _onSave(card),
              style: ElevatedButton.styleFrom(
                backgroundColor: ZenioColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                _mode == 'set'
                    ? 'Set balance'
                    : (_mode == 'add'
                        ? 'Add to balance'
                        : 'Subtract from balance'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
