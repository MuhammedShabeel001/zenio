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
}
