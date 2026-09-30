import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/shared/widgets/dismiss_keyboard_on_tap.dart';

void main() {
  final field = FocusNode();
  final other = FocusNode();
  var pressed = 0;

  setUp(() => pressed = 0);
  tearDownAll(() {
    field.dispose();
    other.dispose();
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => DismissKeyboardOnTap(child: child!),
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  focusNode: field,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                TextButton(
                  onPressed: () => pressed++,
                  child: const Text('Save'),
                ),
                Focus(focusNode: other, child: const Text('Other')),
                const Expanded(child: SizedBox.expand()),
              ],
            ),
          ),
        ),
      );

  testWidgets('a tap outside the field puts the keyboard away', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(field.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tapAt(const Offset(400, 500));
    await tester.pump();

    expect(field.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('buttons still get their taps', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(pressed, 1);
  });

  testWidgets('focus that is not a text field stays', (tester) async {
    await pump(tester);
    other.requestFocus();
    await tester.pump();

    await tester.tapAt(const Offset(400, 500));
    await tester.pump();

    expect(other.hasFocus, isTrue);
  });
}
