import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/settings/domain/models/settings_model.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../../helpers/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Zenio',
      packageName: 'com.aurea.zenio',
      version: '2.0.0',
      buildNumber: '2',
      buildSignature: '',
    );
  });

  test(
      'changing a setting before settings load does not overwrite the others '
      'with defaults', () async {
    const stored = SettingsModel(
      primaryCurrency: 'INR',
      defaultWallet: 'HDFC',
      isBiometricEnabled: false,
      supportEmail: 'support@zenio.app',
      appVersion: 'v 2.0.0',
    );
    SharedPreferences.setMockInitialValues({
      'app_user_settings': jsonEncode(stored.toJson()),
    });
    final storage = TestStorage.create();
    final container = storage.container();
    await container.read(sqlitePrefsProvider.future);

    await container
        .read(settingsNotifierProvider.notifier)
        .updatePrimaryCurrency('USD');

    final sp = await SharedPreferences.getInstance();
    final saved = SettingsModel.fromJson(
      jsonDecode(sp.getString('app_user_settings')!) as Map<String, dynamic>,
    );
    expect(saved.primaryCurrency, 'USD');
    expect(saved.defaultWallet, 'HDFC');
    expect(saved.isBiometricEnabled, isFalse);
  });
}
