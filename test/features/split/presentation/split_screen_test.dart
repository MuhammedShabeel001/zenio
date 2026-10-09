import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/split/presentation/split/split_mobile.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../../helpers/test_storage.dart';

void main() {
  for (final textScale in [1.0, 1.3]) {
    testWidgets('fits a phone screen at ${textScale}x text', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'Zenio',
        packageName: 'com.auren.zenio',
        version: '2.0.0',
        buildNumber: '2',
        buildSignature: '',
      );
      final container = TestStorage.create().container();
      await tester.runAsync(() => container.read(sqlitePrefsProvider.future));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SplitScreenMobile()),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Each person pays'), findsOneWidget);
    });
  }
}
