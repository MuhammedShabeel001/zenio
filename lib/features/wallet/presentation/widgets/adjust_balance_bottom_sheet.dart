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
    this.onRecordTransaction,
    super.key,
  });

  final int cardIndex;

  /// Opens Add transaction instead, for money that really came in or went
  /// out.
  final VoidCallback? onRecordTransaction;

  static void show(BuildContext context, int cardIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: MediaQuery.of(sheetContext).viewInsets,
        child: AdjustBalanceBottomSheet(
          cardIndex: cardIndex,
          // Opened from the screen behind, which stays after this closes.
          onRecordTransaction: () => AddTransactionBottomSheet.show(context),
        ),
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
  String _mode = 'add'; // 'add' (increase), 'subtract' (decrease), 'set'

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool _isSaving = false;
  String? _saveError;

  /// The balance the wallet will have, or null while the entry would not
  /// change it (nothing typed, zero to add or take away, or the same
  /// balance to set).
  double? _newBalance(WalletCardModel card) {
    final text = _amountController.text.trim();
    if (text.isEmpty || text == '-') return null;
    final amount = AppNumberFormat.tryParseAmount(text);
    if (amount == null) return null;
    if (_mode != 'set' && amount <= 0) return null;
    final target = switch (_mode) {
      'add' => card.balance + amount,
      'subtract' => card.balance - amount,
      _ => amount,
    };
    return (target - card.balance).abs() < 0.005 ? null : target;
  }

  Future<void> _onSave(WalletCardModel card) async {
    final target = _newBalance(card);
    if (target == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(walletNotifierProvider.notifier)
          .adjustBalance(card.id, target);
      await HapticFeedback.lightImpact();
      if (!mounted) return;
      ZenioSnackBar.show(
        context,
        message: '${card.bankName} balance is now '
            '${Money.balance(target, symbol: ref.read(currencySymbolProvider))}',
        type: ZenioSnackBarType.success,
      );
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

  /// A mode: neutral, as a correction is neither good nor bad news.
  Widget _buildModeButton(String modeValue, String label) {
    final isSelected = _mode == modeValue;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: GestureDetector(
        onTap: () {
          setState(() {
            _mode = modeValue;
            _amountController.clear();
          });
        },
        child: AnimatedContainer(
          duration: ZenioMotion.of(context, ZenioMotion.fast),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? ZenioColors.textPrimary : ZenioColors.fieldFill,
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
    final newBalance = card == null ? null : _newBalance(card);

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
                'Current: ${Money.balance(card.balance, symbol: currencySymbol)}',
                style: AppFonts.numeric(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ZenioColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            // What an adjustment is, before anything is typed.
            const Text(
              'Corrects the balance to match your real account. Saved as a '
              'balance adjustment in your history, not as income or '
              'spending.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: ZenioColors.textSecondary,
              ),
            ),
            if (widget.onRecordTransaction != null)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onRecordTransaction!();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: ZenioColors.primaryStrong,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text(
                    'Money came in or went out? Add a transaction',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildModeButton('add', 'Increase'),
                const SizedBox(width: 8),
                _buildModeButton('subtract', 'Decrease'),
                const SizedBox(width: 8),
                _buildModeButton('set', 'Set to'),
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
                      textInputAction: TextInputAction.done,
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
            // Where the balance ends up, before saving.
            AnimatedSize(
              duration: ZenioMotion.of(context, ZenioMotion.standard),
              curve: ZenioMotion.standardCurve,
              alignment: Alignment.topCenter,
              child: newBalance == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'New balance: '
                        '${Money.balance(newBalance, symbol: currencySymbol)}',
                        textAlign: TextAlign.center,
                        style: AppFonts.numeric(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ZenioColors.textPrimary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 28),

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

            // Save button
            ElevatedButton(
              onPressed: card == null || newBalance == null || _isSaving
                  ? null
                  : () => _onSave(card),
              style: ElevatedButton.styleFrom(
                backgroundColor: ZenioColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E5EA),
                disabledForegroundColor: ZenioColors.textSecondary,
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
                        ? 'Increase balance'
                        : 'Decrease balance'),
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
