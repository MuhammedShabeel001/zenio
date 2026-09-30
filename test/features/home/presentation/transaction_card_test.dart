import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/presentation/widgets/transaction_card.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';

void main() {
  testWidgets('the Edit button a swipe reveals works with a screen reader',
      (tester) async {
    final semantics = tester.ensureSemantics();
    var edits = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currencyCodeProvider.overrideWithValue('INR')],
        child: MaterialApp(
          home: Scaffold(
            body: TransactionCard(
              transaction: const TransactionModel(
                id: 't1',
                title: 'Food',
                date: '15-09-2026',
                amount: 10,
                currency: 'INR',
                isIncome: false,
                bankName: 'HDFC',
              ),
              onDelete: () {},
              onEdit: () => edits++,
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.text('Food'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    final edit = tester.getSemantics(find.bySemanticsLabel('Edit'));
    expect(edit.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel('Edit'));
    await tester.pumpAndSettle();

    expect(edits, 1);
    semantics.dispose();
  });

  Future<void> pumpRow(
    WidgetTester tester,
    TransactionModel transaction, {
    VoidCallback? onEdit,
    VoidCallback? onTap,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [currencyCodeProvider.overrideWithValue('INR')],
        child: MaterialApp(
          home: Scaffold(
            body: TransactionCard(
              transaction: transaction,
              onDelete: () {},
              onEdit: onEdit,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a row is one item for screen readers, with all its actions',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpRow(
      tester,
      const TransactionModel(
        id: 't1',
        title: 'Food',
        date: '15-09-2026',
        amount: 420,
        currency: 'INR',
        isIncome: false,
        bankName: 'HDFC',
        kind: 'expense',
      ),
      onEdit: () {},
    );

    final row = tester.getSemantics(find.bySemanticsLabel(RegExp('Food')));
    final data = row.getSemanticsData();
    expect(data.label, contains('−₹420.00'));
    expect(row.hintOverrides?.onTapHint, 'edit');
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.hasAction(SemanticsAction.longPress), isTrue);
    expect(
      [
        for (final id in data.customSemanticsActionIds!)
          CustomSemanticsAction.getAction(id)?.label,
      ],
      containsAll(['Edit', 'Delete']),
    );

    // No other tappable node without a label (the old hidden duplicate).
    expect(
      find.semantics.byPredicate(
        (node) =>
            node.getSemanticsData().hasAction(SemanticsAction.tap) &&
            node.getSemanticsData().label.isEmpty,
      ),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('an adjustment shows its details on a tap', (tester) async {
    final semantics = tester.ensureSemantics();
    var shown = 0;
    await pumpRow(
      tester,
      const TransactionModel(
        id: 'a1',
        title: 'Balance adjustment',
        date: '15-09-2026',
        amount: 50,
        currency: 'INR',
        isIncome: true,
        bankName: 'Cash',
        kind: 'adjustment',
      ),
      onTap: () => shown++,
    );

    final row = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Balance adjustment')),
    );
    expect(row.hintOverrides?.onTapHint, 'show details');
    expect(find.byIcon(Icons.exposure_rounded), findsOneWidget);

    await tester.tap(find.text('Balance adjustment'));
    await tester.pump();
    expect(shown, 1);
    semantics.dispose();
  });

  testWidgets('a long title keeps the row whole on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(640, 400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpRow(
      tester,
      const TransactionModel(
        id: 't1',
        title: 'Groceries for the week',
        date: '15-09-2026',
        amount: 1500,
        currency: 'INR',
        isIncome: false,
        bankName: 'HDFC',
      ),
      onEdit: () {},
    );

    // The row's height is fixed, so the title is cut short rather than
    // pushing the date out of the row.
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<Text>(find.text('Groceries for the week')).maxLines,
      1,
    );
    expect(find.text('−₹1,500.00'), findsOneWidget);
  });
}
