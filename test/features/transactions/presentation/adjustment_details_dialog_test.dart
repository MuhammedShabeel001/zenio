import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/implementations/money_tracker/money_tracker_repository.dart';
import 'package:zenio/features/home/domain/repositories/interfaces/money_tracker/i_money_tracker_repository.dart';
import 'package:zenio/features/transactions/presentation/widgets/adjustment_details_dialog.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';

const _adjustment = TransactionModel(
  id: 'a1',
  title: 'Balance adjustment',
  date: '15-09-2026',
  amount: 500,
  currency: 'INR',
  isIncome: true,
  note: 'Counted the cash',
  bankName: 'Cash',
  timestamp: '26-09-15   18 : 30',
  kind: 'adjustment',
);

class _Memory implements IMoneyTrackerRepository {
  final List<TransactionModel> stored = [_adjustment];

  @override
  Future<List<TransactionModel>> getTransactions() async => List.of(stored);

  @override
  Future<void> deleteTransaction(String id) async =>
      stored.removeWhere((tx) => tx.id == id);

  @override
  Future<void> insertTransaction(TransactionModel transaction) async =>
      stored.add(transaction);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _Memory repository;

  Future<void> open(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    repository = _Memory();
    final container = ProviderContainer(
      overrides: [
        currencyCodeProvider.overrideWithValue('INR'),
        moneyTrackerRepositoryRepoProvider.overrideWith((ref) => repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(homeNotifierProvider.notifier).loadMoneyTrackerData();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () =>
                    showAdjustmentDetails(context, ref, _adjustment),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('says what the adjustment did and why it cannot be edited',
      (tester) async {
    await open(tester);

    expect(find.text('Balance adjustment'), findsOneWidget);
    expect(find.text('+₹500.00'), findsOneWidget);
    expect(find.text('Added to Cash'), findsOneWidget);
    expect(find.text('15 Sep 2026 · 18:30'), findsOneWidget);
    expect(find.text('Counted the cash'), findsOneWidget);
    expect(find.textContaining("it can't be edited"), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Added to Cash'), findsNothing);
    expect(repository.stored, hasLength(1));
  });

  testWidgets('Delete removes it, says what went, and Undo restores it',
      (tester) async {
    await open(tester);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.stored, isEmpty);
    expect(
      find.text('Balance adjustment · +₹500.00 deleted'),
      findsOneWidget,
    );

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repository.stored.single.id, 'a1');
  });
}
