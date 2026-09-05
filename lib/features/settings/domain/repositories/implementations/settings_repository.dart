import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/settings/domain/models/settings_model.dart';
import 'package:zenio/features/settings/domain/repositories/interfaces/i_settings_repository.dart';
import 'package:zenio/shared/providers/providers.dart';
import 'package:zenio/shared/services/local_database_service.dart';

part 'settings_repository.g.dart';

class SettingsRepository implements ISettingsRepository {
  SettingsRepository(this._prefs, this._dbService);

  final SqlitePrefs _prefs;
  final LocalDatabaseService _dbService;

  static const String _settingsKey = 'app_user_settings';

  @override
  Future<SettingsModel> getSettings() async {
    var dynamicVersion = 'v 1.0.0';
    try {
      final info = await PackageInfo.fromPlatform();
      dynamicVersion = 'v ${info.version}';
    } catch (_) {}

    final rawJson = _prefs.getString(_settingsKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final map = jsonDecode(rawJson) as Map<String, dynamic>;
        final saved = SettingsModel.fromJson(map);
        return saved.copyWith(appVersion: dynamicVersion);
      } catch (_) {
        // Fallback to default
      }
    }

    final defaultSettings = SettingsModel(
      primaryCurrency: 'INR',
      defaultWallet: '',
      isBiometricEnabled: true,
      supportEmail: 'support@zenio.app',
      appVersion: dynamicVersion,
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
    await _dbService.clearAllData();
    await _prefs.clear();
  }
}

@Riverpod(keepAlive: true)
ISettingsRepository settingsRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sqlitePrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  if (prefs == null) {
    throw Exception('SqlitePrefs not initialized yet');
  }
  final dbService = ref.watch(localDatabaseServiceProvider);
  return SettingsRepository(prefs, dbService);
}
