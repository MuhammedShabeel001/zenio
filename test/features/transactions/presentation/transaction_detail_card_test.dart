import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/presentation/widgets/transaction_detail_card.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';

const _expense = TransactionDetailModel(
  id: 't1',
  title: 'Food',
  date: '15-09-2026',
  amount: 420,
  isIncome: false,
  currency: 'INR',
  note: 'Lunch with the team',
  bankName: 'HDFC',
  timestamp: '26-09-15   13 : 05',
  kind: 'expense',
);

const _adjustment = TransactionDetailModel(
  id: 'a1',
  title: 'Balance adjustment',
  date: '15-09-2026',
  amount: 50,
  isIncome: true,
  currency: 'INR',
  note: 'Counted the cash',
  bankName: 'Cash',
  timestamp: '26-09-15   18 : 30',
  kind: 'adjustment',
);

void main() {
  late int edits;

  Future<void> show(
    WidgetTester tester,
    TransactionDetailModel transaction, {
    bool editable = true,
  }) async {
    edits = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currencyCodeProvider.overrideWithValue('INR')],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TransactionDetailCard(
                transaction: transaction,
                onDelete: () {},
                onEdit: editable ? () => edits++ : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tapping a transaction shows its details, without an Edit button',
      (tester) async {
    await show(tester, _expense);
    expect(find.text('Lunch with the team').hitTestable(), findsNothing);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // The row opens in place, without starting an edit.
    expect(edits, 0);
    expect(find.text('Lunch with the team').hitTestable(), findsOneWidget);
    expect(find.text('HDFC').hitTestable(), findsOneWidget);
    expect(find.text('13:05').hitTestable(), findsOneWidget);
    // Edit is a swipe or a long press away, not repeated in the details.
    expect(find.text('Edit'), findsNothing);

    // A second tap closes it again.
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(find.text('Lunch with the team').hitTestable(), findsNothing);
  });

  testWidgets('a screen reader hears that a tap shows or hides the details',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, _expense);

    SemanticsNode row() =>
        tester.getSemantics(find.bySemanticsLabel(RegExp('Food')));
    expect(row().hintOverrides?.onTapHint, 'show details');
    expect(row().getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    tester.semantics.tap(find.semantics.byLabel(RegExp('Food')));
    await tester.pumpAndSettle();

    expect(row().hintOverrides?.onTapHint, 'hide details');
    expect(find.text('Lunch with the team').hitTestable(), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a long press still offers Edit', (tester) async {
    await show(tester, _expense);

    await tester.longPress(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(edits, 1);
  });

  testWidgets('the Edit button a swipe reveals still works', (tester) async {
    await show(tester, _expense);

    await tester.drag(find.text('Food'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    tester.semantics.tap(find.semantics.byLabel('Edit'));
    await tester.pumpAndSettle();

    expect(edits, 1);
  });

  testWidgets('a transfer shows both wallets', (tester) async {
    await show(
      tester,
      const TransactionDetailModel(
        id: 'x1',
        title: 'Transfer to Cash',
        date: '15-09-2026',
        amount: 1000,
        isIncome: false,
        currency: 'INR',
        bankName: 'HDFC -> Cash',
        timestamp: '26-09-15   09 : 00',
        kind: 'transfer',
        transferFrom: 'HDFC',
        transferTo: 'Cash',
      ),
    );

    await tester.tap(find.text('Transfer to Cash'));
    await tester.pumpAndSettle();

    expect(find.text('HDFC → Cash'), findsOneWidget);
  });

  testWidgets('an adjustment opens the same way and says why it has no Edit',
      (tester) async {
    await show(tester, _adjustment, editable: false);
    // Shown with the Adjust icon, not an income or spending arrow.
    expect(find.byIcon(Icons.exposure_rounded), findsOneWidget);

    await tester.tap(find.text('Balance adjustment'));
    await tester.pumpAndSettle();

    expect(find.text('Counted the cash').hitTestable(), findsOneWidget);
    expect(find.text('Cash').hitTestable(), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.textContaining("can't be edited").hitTestable(), findsOneWidget);
  });

  testWidgets('opened on a small phone with large text, nothing overflows',
      (tester) async {
    tester.view.physicalSize = const Size(640, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await show(
      tester,
      const TransactionDetailModel(
        id: 'x2',
        title: 'Transfer to Savings account',
        date: '15-09-2026',
        // Modest, because the test font draws every letter a full square
        // wide; long wallet names and a long note are what's checked here.
        amount: 1000,
        isIncome: false,
        currency: 'INR',
        note: 'Moving the bonus into savings before the end of the month',
        bankName: 'HDFC Salary account -> Savings account',
        timestamp: '26-09-15   09 : 00',
        kind: 'transfer',
        transferFrom: 'HDFC Salary account',
        transferTo: 'Savings account',
      ),
    );

    await tester.tap(find.text('Transfer to Savings account'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Moving the bonus into savings before the end of the month'),
      findsOneWidget,
    );
  });
}
