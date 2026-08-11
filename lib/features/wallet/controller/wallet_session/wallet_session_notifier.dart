import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/wallet/controller/wallet_session/wallet_session_state.dart';
import 'package:zenio/features/wallet/domain/models/wallet_session_model.dart';
import 'package:zenio/features/wallet/domain/repositories/implementations/wallet_session_repository.dart';

part 'wallet_session_notifier.g.dart';

@Riverpod(keepAlive: true)
class WalletSessionNotifier extends _$WalletSessionNotifier {
  @override
  WalletSessionState build() {
    _loadWallets();
    return WalletSessionState.initial();
  }

  Future<void> _loadWallets() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(walletSessionRepositoryRepoProvider);
      final list = await repo.getWalletSessions();
      state = state.copyWith(
        wallets: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> addWalletSession(WalletSessionModel wallet) async {
    try {
      final repo = ref.read(walletSessionRepositoryRepoProvider);
      await repo.saveWalletSession(wallet);
      await _loadWallets();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateWalletSession(WalletSessionModel wallet) async {
    try {
      final repo = ref.read(walletSessionRepositoryRepoProvider);
      await repo.updateWalletSession(wallet);
      await _loadWallets();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteWalletSession(String walletId) async {
    try {
      final repo = ref.read(walletSessionRepositoryRepoProvider);
      await repo.deleteWalletSession(walletId);
      await _loadWallets();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> toggleFreezeWalletSession(String walletId) async {
    try {
      final repo = ref.read(walletSessionRepositoryRepoProvider);
      await repo.toggleFreezeWalletSession(walletId);
      await _loadWallets();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> clearAllWallets() async {
    try {
      final repo = ref.read(walletSessionRepositoryRepoProvider);
      await repo.clearAllWalletSessions();
      await _loadWallets();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}
