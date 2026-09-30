import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/shared/widgets/zenio_dropdown.dart';

void main() {
  Future<void> pumpField(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width * 2, 600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZenioDropdown<String>(
            value: 'h',
            label: 'From',
            items: const [
              ZenioDropdownItem(
                value: 'h',
                label: 'HDFC Bank',
                subtitle: '₹127,681.00',
              ),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('on a narrow field the balance goes under the wallet name',
      (tester) async {
    await pumpField(tester, 400);

    expect(tester.takeException(), isNull);
    final name = tester.getRect(find.text('HDFC Bank'));
    final balance = tester.getRect(find.text('(₹127,681.00)'));
    // The name keeps its room and the amount is shown whole, below it.
    expect(name.width, greaterThan(0));
    expect(balance.top, greaterThanOrEqualTo(name.bottom));
  });

  testWidgets('on a wide field the balance stays beside the wallet name',
      (tester) async {
    await pumpField(tester, 1000);

    final name = tester.getRect(find.text('HDFC Bank'));
    final balance = tester.getRect(find.text('(₹127,681.00)'));
    expect(balance.left, greaterThan(name.right));
    expect(balance.center.dy, closeTo(name.center.dy, 4));
  });
}
