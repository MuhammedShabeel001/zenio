import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/settings/domain/models/settings_model.dart';
import 'package:zenio/features/vault/controller/vault/vault_notifier.dart';
import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/features/vault/presentation/vault/vault_mobile.dart';
import 'package:zenio/shared/services/secure_key_value_store.dart';
import 'package:zenio/shared/services/secure_platform.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';
import 'package:zenio/shared/widgets/privacy_shield.dart';

import '../../helpers/test_storage.dart';

class _MemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> deleteAllForcibly() async => values.clear();
}

/// A container with Vault Lock set to [vaultLock] and one saved card.
Future<ProviderContainer> _vaultWithCard(
  WidgetTester tester, {
  required bool vaultLock,
}) async {
  SharedPreferences.setMockInitialValues({
    'app_user_settings': jsonEncode(
      SettingsModel(
        primaryCurrency: 'INR',
        defaultWallet: '',
        isBiometricEnabled: vaultLock,
        supportEmail: 'support@zenio.app',
        appVersion: '2.0.0',
      ).toJson(),
    ),
  });
  PackageInfo.setMockInitialValues(
    appName: 'Zenio',
    packageName: 'com.aurea.zenio',
    version: '2.0.0',
    buildNumber: '2',
    buildSignature: '',
  );
  final container = TestStorage.create().container(
    overrides: [
      secureKeyValueStoreProvider.overrideWithValue(_MemorySecureStore()),
    ],
  );
  await tester.runAsync(() async {
    await container.read(sqlitePrefsProvider.future);
    await container
        .read(settingsNotifierProvider.notifier)
        .isVaultLockEnabled();
    container.read(vaultNotifierProvider);
    await container.read(vaultNotifierProvider.notifier).addCard(
          const VaultCardModel(
            id: 'c1',
            cardType: 'Visa',
            cardNumber: '4111111111114242',
            expiry: '12/30',
            cvv: '987',
          ),
        );
  });
  return container;
}

Widget _app(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      builder: (context, child) => PrivacyShield(child: child!),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const VaultScreenMobile(),
                ),
              ),
              child: const Text('Open vault'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _leaveApp(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

Future<void> _returnToApp(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

final _privacyCover = find.byIcon(Icons.lock_rounded);

void main() {
  testWidgets(
      'with Vault Lock on, leaving the app closes the Vault and the cover '
      'goes away once it has closed', (tester) async {
    final container = await _vaultWithCard(tester, vaultLock: true);
    await tester.pumpWidget(_app(container));
    await tester.tap(find.text('Open vault'));
    await tester.pumpAndSettle();

    expect(find.text('•••• •••• •••• 4242'), findsOneWidget);
    expect(find.text('4111111111114242'), findsNothing);
    expect(find.text('987'), findsNothing);

    await _leaveApp(tester);
    expect(_privacyCover, findsOneWidget);

    await _returnToApp(tester);
    expect(
      _privacyCover,
      findsOneWidget,
      reason: 'the Vault must not show while it animates away',
    );

    await tester.pumpAndSettle();
    expect(find.byType(VaultScreenMobile), findsNothing);
    expect(_privacyCover, findsNothing);
    expect(find.text('Open vault'), findsOneWidget);
    expect(SecurePlatform.sensitiveScreenOpen.value, isFalse);
    expect(SecurePlatform.coverUntilClosed.value, isFalse);
  });

  testWidgets(
      'with Vault Lock off, the Vault stays open, is hidden only while the '
      'app is away and hides revealed details again', (tester) async {
    final container = await _vaultWithCard(tester, vaultLock: false);
    await tester.pumpWidget(_app(container));
    await tester.tap(find.text('Open vault'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Show card details'));
    await tester.pump();
    expect(find.text('4111111111114242'), findsOneWidget);

    await _leaveApp(tester);
    expect(_privacyCover, findsOneWidget);

    await _returnToApp(tester);
    await tester.pumpAndSettle();
    expect(find.byType(VaultScreenMobile), findsOneWidget);
    expect(_privacyCover, findsNothing);
    expect(find.text('4111111111114242'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(SecurePlatform.sensitiveScreenOpen.value, isFalse);
    expect(_privacyCover, findsNothing);
  });
}
