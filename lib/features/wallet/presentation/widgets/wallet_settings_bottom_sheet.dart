import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/presentation/widgets/edit_wallet_dialog.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/formatters.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

class WalletSettingsBottomSheet extends ConsumerWidget {
  const WalletSettingsBottomSheet({
    required this.card,
    required this.cardIndex,
    super.key,
  });

  final WalletCardModel card;
  final int cardIndex;

  static void show(BuildContext context, WalletCardModel card, int cardIndex) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => WalletSettingsBottomSheet(
        card: card,
        cardIndex: cardIndex,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(walletNotifierProvider.notifier);
    final count = notifier.transactionCountFor(cardIndex);
    final history = count == 0
        ? ''
        : ' Its ${AppNumberFormat.formatNumber(count)} '
            'transaction${count == 1 ? '' : 's'} will stay in your history.';

    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Delete ${card.bankName}?'),
        content: Text('This removes the wallet and its balance.$history'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: ZenioColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    navigator.pop();
    try {
      await notifier.deleteCard(cardIndex);
      if (!navigator.context.mounted) return;
      ZenioSnackBar.show(
        navigator.context,
        message: '${card.bankName} deleted',
        type: ZenioSnackBarType.success,
      );
    } catch (_) {
      if (!navigator.context.mounted) return;
      ZenioSnackBar.show(
        navigator.context,
        message: "Couldn't delete the wallet. Please try again.",
        type: ZenioSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Card preview header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ZenioColors.sheet,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.bankName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: ZenioColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.cardNumber.isNotEmpty
                            ? '•••• ${card.cardNumber.length >= 4 ? card.cardNumber.substring(card.cardNumber.length - 4) : card.cardNumber}'
                            : card.cardType,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ZenioColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$currencySymbol ${AppNumberFormat.formatAmount(card.balance, alwaysShowDecimals: true)}',
                  style: AppFonts.numeric(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: ZenioColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          ListTile(
            leading: const Icon(Icons.edit, color: Colors.black87),
            title: const Text(
              'Edit Wallet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            onTap: () {
              // Open the dialog from the navigator, not from this closing sheet.
              final navigator = Navigator.of(context)..pop();
              EditWalletDialog.show(
                navigator.context,
                card: card,
                cardIndex: cardIndex,
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text(
              'Delete Wallet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            onTap: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }
}
