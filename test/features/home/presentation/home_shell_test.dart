import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/home/home.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../../helpers/test_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Zenio',
      packageName: 'com.aurea.zenio',
      version: '2.0.0',
      buildNumber: '2',
      buildSignature: '',
    );
  });

  IndexedStack stack(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack));

  testWidgets('switches tabs and Android back returns to Home first',
      (tester) async {
    final storage = TestStorage.create();
    final container = storage.container();
    await tester.runAsync(() => container.read(sqlitePrefsProvider.future));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    expect(stack(tester).index, 0);

    await tester.tap(find.bySemanticsLabel('Wallets'));
    await tester.pump();
    expect(stack(tester).index, 1);

    // System back on a tab other than Home goes to Home.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(stack(tester).index, 0);

    // Both tabs stay built, so their state survives switching.
    expect(find.byType(HomeScreenMobile), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Wallets'));
    await tester.pump();
    expect(find.byType(HomeScreenMobile, skipOffstage: false), findsOneWidget);
  });
}
