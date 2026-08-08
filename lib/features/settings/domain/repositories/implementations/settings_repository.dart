import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/settings/domain/models/settings_model.dart';
import 'package:zenio/features/settings/domain/repositories/interfaces/i_settings_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'settings_repository.g.dart';

class SettingsRepository implements ISettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _settingsKey = 'app_user_settings';

  @override
  Future<SettingsModel> getSettings() async {
    final rawJson = _prefs.getString(_settingsKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final map = jsonDecode(rawJson) as Map<String, dynamic>;
        return SettingsModel.fromJson(map);
      } catch (_) {
        // Fallback to default
      }
    }

    const defaultSettings = SettingsModel(
      primaryCurrency: 'INR',
      defaultWallet: 'SBI (Debit Card)',
      isBiometricEnabled: true,
      supportEmail: 'support@zenio.app',
      appVersion: 'vv 3.00.00',
    );
    await saveSettings(defaultSettings);
    return defaultSettings;
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    final jsonStr = jsonEncode(settings.toJson());
    await _prefs.setString(_settingsKey, jsonStr);
  }

  @override
  Future<void> clearAllAppData() async {
    await _prefs.clear();
  }
}

@Riverpod(keepAlive: true)
ISettingsRepository settingsRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized yet');
  }
  return SettingsRepository(prefs);
}
