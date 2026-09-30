import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/summary/financial_summary_model.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/implementations/money_tracker/money_tracker_repository.dart';
import 'package:zenio/features/home/domain/repositories/interfaces/money_tracker/i_money_tracker_repository.dart';
import 'package:zenio/features/home/presentation/widgets/delete_transaction_with_undo.dart';

import '../../../helpers/test_storage.dart';

/// Transactions kept in memory. Like the database, it refuses to insert an
/// id that is already there.
class _MemoryTransactions implements IMoneyTrackerRepository {
  final Map<String, TransactionModel> rows = {};

  @override
  Future<List<TransactionModel>> getTransactions() async =>
      rows.values.toList();

  @override
  Future<void> insertTransaction(TransactionModel transaction) async {
    if (rows.containsKey(transaction.id)) {
      throw StateError('Transaction ${transaction.id} already exists.');
    }
    rows[transaction.id] = transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async => rows.remove(id);

  @override
  Future<void> saveSummary(FinancialSummaryModel summary) async {}

  @override
  Future<FinancialSummaryModel> getSummary() => throw UnimplementedError();

  @override
  Future<void> updateTransaction(TransactionModel transaction) =>
      throw UnimplementedError();

  @override
  Future<void> renameWallet(String oldName, String newName) =>
      throw UnimplementedError();
}

void main() {
  testWidgets('tapping Undo twice restores the transaction once, quietly',
      (tester) async {
    // Haptic feedback goes to the platform, which is not there in tests.
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final repository = _MemoryTransactions();
    repository.rows['t1'] = sampleTransaction('t1');
    final container = ProviderContainer(
      overrides: [
        moneyTrackerRepositoryRepoProvider.overrideWith((ref) => repository),
      ],
    );
    addTearDown(container.dispose);
    container.read(homeNotifierProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => deleteTransactionWithUndo(context, ref, 't1'),
                child: const Text('Delete'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(repository.rows, isEmpty);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    // Still on screen while it slides away.
    await tester.tap(find.text('Undo'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't restore the transaction."), findsNothing);
    expect(repository.rows.keys, ['t1']);
    expect(
      container.read(homeNotifierProvider).transactions.map((t) => t.id),
      ['t1'],
    );
  });
}
