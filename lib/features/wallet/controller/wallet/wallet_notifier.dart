import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/repositories/implementations/wallet_repository.dart';
import 'package:zenio/features/wallet/domain/repositories/interfaces/i_wallet_repository.dart';

part 'wallet_notifier.freezed.dart';
part 'wallet_notifier.g.dart';
part 'wallet_state.dart';

@Riverpod(keepAlive: true)
class WalletNotifier extends _$WalletNotifier {
  IWalletRepository? _walletRepository;

  @override
  WalletState build() {
    try {
      _walletRepository = ref.watch(walletRepositoryRepoProvider);
      Future.microtask(loadWalletData);
    } catch (_) {
      // SqlitePrefs async handling
    }

    return WalletState.initial();
  }

  double _calculateTotalBalance(List<WalletCardModel> cards) {
    return cards.where((c) => !c.isFrozen).fold(0.0, (sum, c) => sum + c.balance);
  }

  Future<void> loadWalletData() async {
    if (_walletRepository == null) return;
    state = state.copyWith(status: WalletStatus.loading);
    try {
      final cards = await _walletRepository!.getCards();
      final totalBalance = _calculateTotalBalance(cards);
      // Ensure the saved balance matches computed balance
      await _walletRepository!.saveCardBalance(totalBalance);
      
      state = state.copyWith(
        status: WalletStatus.success,
        cardBalance: totalBalance,
        cards: cards,
      );
    } catch (e) {
      state = state.copyWith(status: WalletStatus.error);
    }
  }

  void onCardPageChanged(int index) {
    state = state.copyWith(activeCardIndex: index);
  }

  Future<void> updateCardBalance(int index, double amount, {required String mode}) async {
    if (_walletRepository == null) return;
    
    final card = state.cards[index];
    double newCardBalance;
    
    if (mode == 'set') {
      newCardBalance = amount;
    } else if (mode == 'add') {
      newCardBalance = card.balance + amount;
    } else if (mode == 'subtract') {
      newCardBalance = card.balance - amount;
    } else {
      return;
    }
    
    final updatedCard = card.copyWith(balance: newCardBalance);
    final updatedCards = List<WalletCardModel>.from(state.cards);
    updatedCards[index] = updatedCard;
    
    await _walletRepository!.saveCards(updatedCards);
    
    final totalBalance = _calculateTotalBalance(updatedCards);
    await _walletRepository!.saveCardBalance(totalBalance);
    
    state = state.copyWith(
      cards: updatedCards,
      cardBalance: totalBalance,
    );
  }

  Future<void> toggleFreezeCard() async {
    if (_walletRepository == null || state.cards.isEmpty) return;
    
    final actualIndex = state.activeCardIndex % state.cards.length;
    final card = state.cards[actualIndex];
    final updatedCard = card.copyWith(isFrozen: !card.isFrozen);
    
    final updatedCards = List<WalletCardModel>.from(state.cards);
    updatedCards[actualIndex] = updatedCard;
    
    await _walletRepository!.saveCards(updatedCards);
    
    final totalBalance = _calculateTotalBalance(updatedCards);
    await _walletRepository!.saveCardBalance(totalBalance);
    
    state = state.copyWith(
      cards: updatedCards,
      cardBalance: totalBalance,
    );
  }

  Future<void> addCard(WalletCardModel card, double initialBalance) async {
    if (_walletRepository == null) return;
    
    // Add the new card to the list
    final updatedCards = List<WalletCardModel>.from(state.cards)..add(card);
    await _walletRepository!.saveCards(updatedCards);
    
    final totalBalance = _calculateTotalBalance(updatedCards);
    await _walletRepository!.saveCardBalance(totalBalance);
    
    // If this is the user's first wallet, automatically set as default
    if (updatedCards.length == 1) {
      try {
        await ref
            .read(settingsNotifierProvider.notifier)
            .updateDefaultWallet(card.bankName);
      } catch (_) {}
    }

    state = state.copyWith(
      cards: updatedCards,
      cardBalance: totalBalance,
      // Focus on the newly added card
      activeCardIndex: updatedCards.length - 1,
    );
  }

  Future<void> editCard(int index, WalletCardModel newCard) async {
    if (_walletRepository == null) return;
    final oldCard = state.cards[index];
    final updatedCards = List<WalletCardModel>.from(state.cards);
    updatedCards[index] = newCard;
    await _walletRepository!.saveCards(updatedCards);
    final totalBalance = _calculateTotalBalance(updatedCards);
    await _walletRepository!.saveCardBalance(totalBalance);

    // If default wallet was renamed, keep default synchronized
    if (oldCard.bankName.trim().toLowerCase() !=
        newCard.bankName.trim().toLowerCase()) {
      try {
        final currentDefault =
            ref.read(settingsNotifierProvider).settings.defaultWallet;
        if (currentDefault.trim().toLowerCase() ==
            oldCard.bankName.trim().toLowerCase()) {
          await ref
              .read(settingsNotifierProvider.notifier)
              .updateDefaultWallet(newCard.bankName);
        }
      } catch (_) {}
    }

    state = state.copyWith(
      cards: updatedCards,
      cardBalance: totalBalance,
    );
  }

  Future<void> deleteCard(int index) async {
    if (_walletRepository == null) return;
    final deletedCard = state.cards[index];
    final updatedCards = List<WalletCardModel>.from(state.cards)..removeAt(index);
    await _walletRepository!.saveCards(updatedCards);
    final totalBalance = _calculateTotalBalance(updatedCards);
    await _walletRepository!.saveCardBalance(totalBalance);
    
    // If the deleted card was default, update default to next available card
    try {
      final currentDefault =
          ref.read(settingsNotifierProvider).settings.defaultWallet;
      if (currentDefault.trim().toLowerCase() ==
          deletedCard.bankName.trim().toLowerCase()) {
        if (updatedCards.isNotEmpty) {
          await ref
              .read(settingsNotifierProvider.notifier)
              .updateDefaultWallet(updatedCards.first.bankName);
        }
      }
    } catch (_) {}

    // Adjust activeCardIndex if necessary
    int newActiveIndex = state.activeCardIndex;
    if (updatedCards.isEmpty) {
      newActiveIndex = 0;
    } else if (newActiveIndex >= updatedCards.length) {
      newActiveIndex = updatedCards.length - 1;
    }
    
    state = state.copyWith(
      cards: updatedCards,
      cardBalance: totalBalance,
      activeCardIndex: newActiveIndex,
    );
  }

  Future<void> adjustWalletBalance({
    required String walletName,
    required double amount,
    required bool isIncome,
  }) async {
    final index = state.cards.indexWhere(
      (c) => c.bankName.trim().toLowerCase() == walletName.trim().toLowerCase(),
    );
    if (index != -1) {
      await updateCardBalance(
        index,
        amount,
        mode: isIncome ? 'add' : 'subtract',
      );
    }
  }

  Future<void> transferBetweenWallets({
    required String fromWallet,
    required String toWallet,
    required double amount,
  }) async {
    final fromIndex = state.cards.indexWhere(
      (c) => c.bankName.trim().toLowerCase() == fromWallet.trim().toLowerCase(),
    );
    if (fromIndex != -1) {
      await updateCardBalance(fromIndex, amount, mode: 'subtract');
    }

    final toIndex = state.cards.indexWhere(
      (c) => c.bankName.trim().toLowerCase() == toWallet.trim().toLowerCase(),
    );
    if (toIndex != -1) {
      await updateCardBalance(toIndex, amount, mode: 'add');
    }
  }
}
