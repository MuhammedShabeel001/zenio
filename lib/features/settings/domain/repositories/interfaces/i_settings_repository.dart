import 'package:zenio/features/settings/domain/models/settings_model.dart';

abstract class ISettingsRepository {
  Future<SettingsModel> getSettings();
  Future<void> saveSettings(SettingsModel settings);
  Future<void> clearAllAppData();
}
