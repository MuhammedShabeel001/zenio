import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/splash/presentation/widgets/animated_zenio_logo.dart';
import 'package:zenio/features/splash/splash.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('renders SplashScreen with branding elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Verify that the 'by aureo' subtitle text is present in the tree
      expect(find.text('by aureo'), findsOneWidget);
      expect(find.byType(AnimatedZenioLogo), findsOneWidget);

      // Allow animation to progress through reveal and shine sweep
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1000));
    });

    testWidgets('renders on mobile screen layout', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenMobile(),
        ),
      );

      expect(find.text('by aureo'), findsOneWidget);
      expect(find.byType(AnimatedZenioLogo), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1000));
    });

    testWidgets('renders on web/desktop layout', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreenWeb(),
        ),
      );

      expect(find.text('by aureo'), findsOneWidget);
      expect(find.byType(AnimatedZenioLogo), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1000));
    });
  });
}
