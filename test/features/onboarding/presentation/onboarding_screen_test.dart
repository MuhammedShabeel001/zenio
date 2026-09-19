import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('renders first slide with title and navigation controls',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      // Verify first slide title and subtitle are present
      expect(find.text('Find Your Financial Zen'), findsOneWidget);
      expect(
        find.textContaining('Take a deep breath'),
        findsOneWidget,
      );

      // Verify Skip button is present on the first slide
      expect(find.text('Skip'), findsOneWidget);

      // Verify forward button is present
      expect(
        find.byKey(const ValueKey('onboarding_next_button')),
        findsOneWidget,
      );
    });

    testWidgets('can advance to next slide', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreenMobile(),
          ),
        ),
      );

      expect(find.text('Find Your Financial Zen'), findsOneWidget);

      // Tap Next button
      await tester.tap(find.byKey(const ValueKey('onboarding_next_button')));
      await tester.pumpAndSettle();

      // Verify second slide is now active
      expect(find.text('Clarity at a Glance'), findsOneWidget);
      expect(
        find.textContaining('Manage multiple wallets'),
        findsOneWidget,
      );

      // Verify Back button is now interactive
      expect(
        find.byKey(const ValueKey('onboarding_prev_button')),
        findsOneWidget,
      );
    });

    testWidgets('navigates to last slide and shows Enter Zenio button',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreenMobile(),
          ),
        ),
      );

      // Advance through all slides to the last slide
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('onboarding_next_button')));
        await tester.pumpAndSettle();
      }

      // Verify 4th slide is visible
      expect(find.text('Build Your Vault'), findsOneWidget);
      expect(
        find.textContaining('Set meaningful savings goals'),
        findsOneWidget,
      );

      // Skip button should no longer be visible
      expect(find.text('Skip'), findsNothing);

      // Enter Zenio button should be displayed
      expect(
        find.byKey(const ValueKey('onboarding_enter_button')),
        findsOneWidget,
      );
    });

    testWidgets('tapping Enter Zenio prompts user to add first wallet',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreenMobile(),
          ),
        ),
      );

      // Advance to final slide
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('onboarding_next_button')));
        await tester.pumpAndSettle();
      }

      // Tap Enter Zenio
      await tester.tap(find.byKey(const ValueKey('onboarding_enter_button')));
      await tester.pumpAndSettle();

      // Verify Add your first wallet bottom sheet is displayed
      expect(find.text('Add your first wallet'), findsOneWidget);
      expect(find.text('Add Wallet & Enter Zenio'), findsOneWidget);
    });
  });
}
