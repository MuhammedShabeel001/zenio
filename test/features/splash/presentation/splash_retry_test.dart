import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/splash/splash.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

void main() {
  testWidgets('after a failed start, tapping anywhere tries again',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var attempts = 0;
    final container = ProviderContainer(
      overrides: [
        sqlitePrefsProvider.overrideWith((ref) async {
          attempts++;
          throw StateError('Local storage could not be opened.');
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SplashScreenMobile()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump();
    expect(find.text("Zenio couldn't open your data."), findsOneWidget);
    expect(attempts, 1);

    await tester.tapAt(const Offset(20, 60));
    await tester.pump();

    expect(attempts, 2);
    await tester.pump(const Duration(seconds: 2));
  });
}
