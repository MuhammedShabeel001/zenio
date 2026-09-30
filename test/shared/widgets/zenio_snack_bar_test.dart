import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

Widget _app() {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => ZenioSnackBar.show(
            context,
            message: 'Transaction deleted',
            duration: const Duration(seconds: 5),
            actionLabel: 'Undo',
            onAction: () {},
          ),
          child: const Text('Delete'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('an action closes with the snack bar after its duration',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('with a screen reader, an action stays until it is used',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(_app());
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);
  });
}
