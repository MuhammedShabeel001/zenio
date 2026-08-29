import 'package:zenio/shared/providers/providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/repositories/implementations/wallet_repository.dart';
import 'package:zenio/features/wallet/domain/repositories/interfaces/i_wallet_repository.dart';

part 'wallet_notifier.freezed.dart';
part 'wallet_notifier.g.dart';
part 'wallet_state.dart';

@Riverpod()
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

  Future<void> loadWalletData() async {
    if (_walletRepository == null) return;
    state = state.copyWith(status: WalletStatus.loading);
    try {
      final balance = await _walletRepository!.getCardBalance();
      final cards = await _walletRepository!.getCards();
      state = state.copyWith(
        status: WalletStatus.success,
        cardBalance: balance,
        cards: cards,
      );
    } catch (e) {
      state = state.copyWith(status: WalletStatus.error);
    }
  }

  void onCardPageChanged(int index) {
    state = state.copyWith(activeCardIndex: index);
  }

  Future<void> topUpBalance(double amount) async {
    if (_walletRepository == null) return;
    final newBalance = state.cardBalance + amount;
    await _walletRepository!.saveCardBalance(newBalance);
    state = state.copyWith(cardBalance: newBalance);
  }

  void toggleFreezeCard() {
    state = state.copyWith(isFrozen: !state.isFrozen);
  }
}
