import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/settings/controller/settings/settings_state.dart';
import 'package:zenio/features/settings/domain/repositories/implementations/settings_repository.dart';

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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
