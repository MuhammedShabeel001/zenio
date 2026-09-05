import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/debts/controller/debts/debts_notifier.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/settings/controller/settings/settings_state.dart';
import 'package:zenio/features/settings/domain/repositories/implementations/settings_repository.dart';
import 'package:zenio/features/split/controller/split/split_notifier.dart';
import 'package:zenio/features/subscriptions/controller/categories/subscription_categories_notifier.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/vault/controller/vault/vault_notifier.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';

part 'settings_notifier.g.dart';

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState.initial();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(settingsRepositoryRepoProvider);
      final settings = await repo.getSettings();
      state = state.copyWith(
        settings: settings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> toggleBiometric(bool value) async {
    final updated = state.settings.copyWith(isBiometricEnabled: value);
    state = state.copyWith(settings: updated);
    try {
      final repo = ref.read(settingsRepositoryRepoProvider);
      await repo.saveSettings(updated);
    } catch (_) {}
  }

  Future<void> updatePrimaryCurrency(String currency) async {
    final updated = state.settings.copyWith(primaryCurrency: currency);
    state = state.copyWith(settings: updated);
    try {
      final repo = ref.read(settingsRepositoryRepoProvider);
      await repo.saveSettings(updated);
    } catch (_) {}
  }

  Future<void> updateDefaultWallet(String walletName) async {
    final updated = state.settings.copyWith(defaultWallet: walletName);
    state = state.copyWith(settings: updated);
    try {
      final repo = ref.read(settingsRepositoryRepoProvider);
      await repo.saveSettings(updated);
    } catch (_) {}
  }

  Future<void> clearAllData() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(settingsRepositoryRepoProvider);
      await repo.clearAllAppData();
      await _loadSettings();

      // Reset all feature notifiers so the in-memory state matches the clean database
      try {
        await ref.read(homeNotifierProvider.notifier).loadMoneyTrackerData();
      } catch (_) {}
      try {
        await ref.read(walletNotifierProvider.notifier).loadWalletData();
      } catch (_) {}
      try {
        await ref.read(vaultNotifierProvider.notifier).loadData();
      } catch (_) {}
      try {
        await ref.read(subscriptionsNotifierProvider.notifier).loadData();
      } catch (_) {}
      try {
        await ref.read(debtsNotifierProvider.notifier).loadData();
      } catch (_) {}
      try {
        await ref.read(splitNotifierProvider.notifier).loadData();
      } catch (_) {}
      try {
        await ref.read(categoriesNotifierProvider.notifier).resetCategories();
      } catch (_) {}
      try {
        await ref
            .read(subscriptionCategoriesNotifierProvider.notifier)
            .resetCategories();
      } catch (_) {}
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
