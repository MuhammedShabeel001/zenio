import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/presentation/widgets/add_wallet_bottom_sheet.dart';

class WalletSettingsBottomSheet extends ConsumerWidget {
  const WalletSettingsBottomSheet({
    required this.card,
    required this.cardIndex,
    super.key,
  });

  final WalletCardModel card;
  final int cardIndex;

  static void show(BuildContext context, WalletCardModel card, int cardIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => WalletSettingsBottomSheet(
        card: card,
        cardIndex: cardIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const SizedBox(height: 24),
          
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
              Navigator.of(context).pop();
              AddWalletBottomSheet.show(context, editingCard: card, editingIndex: cardIndex);
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
            onTap: () {
              ref.read(walletNotifierProvider.notifier).deleteCard(cardIndex);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
