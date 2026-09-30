import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/settings/domain/models/settings_model.dart';
import 'package:zenio/features/settings/domain/repositories/interfaces/i_settings_repository.dart';
import 'package:zenio/shared/providers/providers.dart';

part 'settings_repository.g.dart';

class SettingsRepository implements ISettingsRepository {
  SettingsRepository(this._prefs, this._dbService);

  final SqlitePrefs _prefs;
  final LocalDatabaseService _dbService;

  static const String _settingsKey = 'app_user_settings';
  static const String _keyPrimaryCurrency = 'primary_currency';
  static const String _keyDefaultWallet = 'default_wallet';
  static const String _keyIsBiometricEnabled = 'is_biometric_enabled';
  static const String _keySupportEmail = 'support_email';
  static const String _keyAppVersion = 'app_version';

  @override
  Future<SettingsModel> getSettings() async {
    var dynamicVersion = 'v 1.0.0';
    try {
      final info = await PackageInfo.fromPlatform();
      dynamicVersion = 'v ${info.version}';
    } catch (_) {}

    // 1. Try reading from SharedPreferences first
    try {
      final sp = await SharedPreferences.getInstance();
      final spJson = sp.getString(_settingsKey);
      if (spJson != null && spJson.isNotEmpty) {
        try {
          final map = jsonDecode(spJson) as Map<String, dynamic>;
          final saved = SettingsModel.fromJson(map);
          // Keep SqlitePrefs synchronized
          await _prefs.setString(_settingsKey, spJson);
          return saved.copyWith(appVersion: dynamicVersion);
        } catch (_) {}
      }

      // Check if individual keys were stored in SharedPreferences
      if (sp.containsKey(_keyPrimaryCurrency) ||
          sp.containsKey(_keyIsBiometricEnabled)) {
        final saved = SettingsModel(
          primaryCurrency: sp.getString(_keyPrimaryCurrency) ?? 'INR',
          defaultWallet: sp.getString(_keyDefaultWallet) ?? '',
          isBiometricEnabled: sp.getBool(_keyIsBiometricEnabled) ?? false,
          supportEmail: sp.getString(_keySupportEmail) ?? 'support@zenio.app',
          appVersion: dynamicVersion,
        );
        await saveSettings(saved);
        return saved;
      }
    } catch (_) {}

    // 2. Fall back to SqlitePrefs if SharedPreferences had no usable copy.
    final saved =
        await _prefs.readJsonObject(_settingsKey, SettingsModel.fromJson);
    if (saved != null) {
      // Sync to SharedPreferences for future reads
      try {
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_settingsKey, jsonEncode(saved.toJson()));
      } catch (_) {}
      return saved.copyWith(appVersion: dynamicVersion);
    }

    // Nothing stored yet: use defaults without writing them, so a failed
    // read can never be turned into an overwrite. Vault Lock starts off and
    // is only turned on by the user.
    return SettingsModel(
      primaryCurrency: 'INR',
      defaultWallet: '',
      isBiometricEnabled: false,
      supportEmail: 'support@zenio.app',
      appVersion: dynamicVersion,
    );
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    final jsonStr = jsonEncode(settings.toJson());

    // 1. Save to SqlitePrefs
    await _prefs.setString(_settingsKey, jsonStr);

    // 2. Save to SharedPreferences (both full JSON payload and individual keys)
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_settingsKey, jsonStr);
      await sp.setString(_keyPrimaryCurrency, settings.primaryCurrency);
      await sp.setString(_keyDefaultWallet, settings.defaultWallet);
      await sp.setBool(_keyIsBiometricEnabled, settings.isBiometricEnabled);
      await sp.setString(_keySupportEmail, settings.supportEmail);
      await sp.setString(_keyAppVersion, settings.appVersion);
    } catch (_) {}
  }

  @override
  Future<void> clearAllAppData() async {
    await _dbService.clearAllData();
    await _prefs.clear();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_settingsKey);
      await sp.remove(_keyPrimaryCurrency);
      await sp.remove(_keyDefaultWallet);
      await sp.remove(_keyIsBiometricEnabled);
      await sp.remove(_keySupportEmail);
      await sp.remove(_keyAppVersion);
    } catch (_) {}
  }
}

@Riverpod(keepAlive: true)
ISettingsRepository settingsRepositoryRepo(Ref ref) {
  final prefs = ref.watch(sqlitePrefsProvider).valueOrNull;
  if (prefs == null) {
    throw StateError('Local storage is not ready yet.');
  }
  final dbService = ref.watch(localDatabaseServiceProvider);
  return SettingsRepository(prefs, dbService);
}
