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
  late int detailsShown;

  Future<void> show(
    WidgetTester tester,
    TransactionDetailModel transaction, {
    bool editable = true,
  }) async {
    edits = 0;
    detailsShown = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currencyCodeProvider.overrideWithValue('INR')],
        child: MaterialApp(
          home: Scaffold(
            body: TransactionDetailCard(
              transaction: transaction,
              onDelete: () {},
              onEdit: editable ? () => edits++ : null,
              onTap: editable ? null : () => detailsShown++,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tapping a transaction opens it for editing straight away',
      (tester) async {
    await show(tester, _expense);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    expect(edits, 1);
    // No details panel with a second Edit button on the way.
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('a screen reader hears that a tap edits it', (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, _expense);

    final row = tester.getSemantics(find.bySemanticsLabel(RegExp('Food')));
    expect(row.hintOverrides?.onTapHint, 'edit');
    expect(row.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
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

  testWidgets(
      'an adjustment, which cannot be edited, shows its details instead',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, _adjustment, editable: false);

    final row = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Balance adjustment')),
    );
    expect(row.hintOverrides?.onTapHint, 'show details');

    await tester.tap(find.text('Balance adjustment'));
    await tester.pumpAndSettle();

    expect(edits, 0);
    expect(detailsShown, 1);
    // Shown with the Adjust icon, not an income or spending arrow.
    expect(find.byIcon(Icons.exposure_rounded), findsOneWidget);
    semantics.dispose();
  });
}
