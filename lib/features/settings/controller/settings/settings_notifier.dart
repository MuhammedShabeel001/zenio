import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/debts/controller/debts/debts_notifier.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/settings/controller/settings/settings_state.dart';
import 'package:zenio/features/settings/domain/models/settings_model.dart';
import 'package:zenio/features/settings/domain/repositories/implementations/settings_repository.dart';
import 'package:zenio/features/settings/domain/repositories/interfaces/i_settings_repository.dart';
import 'package:zenio/features/split/controller/split/split_notifier.dart';
import 'package:zenio/features/subscriptions/controller/categories/subscription_categories_notifier.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/vault/controller/vault/vault_notifier.dart';
import 'package:zenio/features/vault/domain/repositories/implementations/vault_repository.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';

part 'settings_notifier.g.dart';

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  ISettingsRepository? _repository;
  Future<void>? _initialLoad;
  bool _loaded = false;

  @override
  SettingsState build() {
    _loaded = false;
    try {
      _repository = ref.watch(settingsRepositoryRepoProvider);
      _initialLoad = Future.microtask(_loadSettings);
    } catch (_) {
      // Local storage is still opening; this notifier rebuilds once it is.
      _repository = null;
      _initialLoad = null;
    }
    return SettingsState.initial();
  }

  Future<void> _loadSettings() async {
    final repo = _repository;
    if (repo == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final settings = await repo.getSettings();
      state = state.copyWith(
        settings: settings,
        isLoading: false,
        errorMessage: null,
      );
      _loaded = true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Saves [update] applied to the loaded settings. Refuses to save while the
  /// stored settings are unknown, so defaults never overwrite real settings.
  Future<void> _update(SettingsModel Function(SettingsModel) update) async {
    await _initialLoad;
    final repo = _repository;
    if (repo == null || !_loaded) {
      throw StateError('Settings are not loaded yet.');
    }
    final updated = update(state.settings);
    // Only show the change once it is saved, so a failed save cannot leave
    // a setting (such as Vault Lock) looking on for this session only.
    await repo.saveSettings(updated);
    state = state.copyWith(settings: updated);
  }

  /// Turns Vault Lock on or off. Stored as `isBiometricEnabled` for
  /// compatibility with existing saved settings.
  Future<void> setVaultLock({required bool enabled}) {
    return _update((s) => s.copyWith(isBiometricEnabled: enabled));
  }

  /// Whether opening the Vault requires device authentication. Waits for the
  /// stored settings; if they cannot be read, the Vault stays locked.
  Future<bool> isVaultLockEnabled() async {
    await _initialLoad;
    if (!_loaded) await _loadSettings();
    return vaultLockRequired;
  }

  /// Whether the Vault must be locked right now. True while the stored
  /// settings are unknown, so a failed load never unlocks it.
  bool get vaultLockRequired => !_loaded || state.settings.isBiometricEnabled;

  Future<void> updatePrimaryCurrency(String currency) async {
    try {
      await _update((s) => s.copyWith(primaryCurrency: currency));
    } catch (_) {}
  }

  Future<void> updateDefaultWallet(String walletName) async {
    try {
      await _update((s) => s.copyWith(defaultWallet: walletName));
    } catch (_) {}
  }

  /// Deletes all app data and resets every feature. Throws if it fails.
  Future<void> clearAllData() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _repository;
      if (repo == null) {
        throw StateError('Local storage is not ready yet.');
      }
      // The vault lives in secure storage, outside the database. If it cannot
      // be cleared, clear everything else and report the failure afterwards.
      Object? vaultError;
      try {
        await ref.read(vaultRepositoryRepoProvider).clearAll();
      } catch (e) {
        vaultError = e;
      }
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
      if (vaultError != null) throw vaultError;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      // Let the caller tell the user; the data may be only partly cleared.
      rethrow;
    }
  }
}
