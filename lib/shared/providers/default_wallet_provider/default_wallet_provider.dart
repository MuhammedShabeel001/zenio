import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';

final defaultWalletProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsNotifierProvider).settings;
  final walletState = ref.watch(walletNotifierProvider);
  final cards = walletState.cards;

  if (cards.isEmpty) {
    return settings.defaultWallet;
  }

  // Look for exact or case-insensitive match in user's cards
  final matchingCard = cards.cast<WalletCardModel?>().firstWhere(
    (c) =>
        c != null &&
        c.bankName.trim().toLowerCase() ==
            settings.defaultWallet.trim().toLowerCase(),
    orElse: () => null,
  );

  if (matchingCard != null) {
    return matchingCard.bankName;
  }

  // Fallback to first card if saved default does not match
  return cards.first.bankName;
});
