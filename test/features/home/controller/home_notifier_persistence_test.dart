import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../../helpers/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TestStorage> storageWithHistory(int count) async {
    final storage = TestStorage.create();
    final db = storage.open();
    for (var i = 0; i < count; i++) {
      await seedTransaction(db, sampleTransaction('old-$i'));
    }
    return storage;
  }

  group('HomeNotifier persistence', () {
    test(
        'adding right after the notifier is (re)created keeps the history '
        '(regression: first add from the Wallet tab wiped all transactions)',
        () async {
      final storage = await storageWithHistory(3);
      final container = storage.container();
      await container.read(sqlitePrefsProvider.future);

      // Recreate the notifier, then add before its initial load has run.
      container.invalidate(homeNotifierProvider);
      await container
          .read(homeNotifierProvider.notifier)
          .addTransaction(sampleTransaction('new'));

      final rows = await storage.transactionRows();
      expect(rows.map((r) => r['id']),
          containsAll(['old-0', 'old-1', 'old-2', 'new']),);
      expect(rows, hasLength(4));
      expect(container.read(homeNotifierProvider).transactions, hasLength(4));
    });

    test('stays alive when nothing is listening (tab switch)', () async {
      final storage = await storageWithHistory(2);
      final container = storage.container();
      await container.read(sqlitePrefsProvider.future);

      final subscription = container.listen(homeNotifierProvider, (_, __) {});
      await container
          .read(homeNotifierProvider.notifier)
          .addTransaction(sampleTransaction('first'));
      subscription.close();
      await Future<void>.delayed(Duration.zero);

      await container
          .read(homeNotifierProvider.notifier)
          .addTransaction(sampleTransaction('second'));

      expect(await storage.transactionRows(), hasLength(4));
    });

    test('an unreadable row is skipped, never deleted', () async {
      final storage = await storageWithHistory(2);
      final db = await storage.open().database;
      // SQLite keeps the text as-is, so the row cannot be decoded.
      await db.insert('transactions', {
        'id': 'corrupt',
        'title': 'Broken',
        'date': '01-09-2026',
        'amount': 'not a number',
        'currency': 'INR',
        'is_income': 0,
      });

      final container = storage.container();
      await container.read(sqlitePrefsProvider.future);
      final notifier = container.read(homeNotifierProvider.notifier);
      await notifier.addTransaction(sampleTransaction('new'));

      final state = container.read(homeNotifierProvider);
      expect(state.status, HomeStatus.success);
      expect(state.transactions.map((t) => t.id), isNot(contains('corrupt')));
      expect(state.transactions, hasLength(3));

      final rows = await storage.transactionRows();
      expect(rows.map((r) => r['id']), contains('corrupt'));
      expect(rows, hasLength(4));
    });

    test('update and delete touch only their own row', () async {
      final storage = await storageWithHistory(3);
      final container = storage.container();
      await container.read(sqlitePrefsProvider.future);
      final notifier = container.read(homeNotifierProvider.notifier);

      await notifier.updateTransaction(sampleTransaction('old-1', amount: 42));
      await notifier.deleteTransaction('old-2');

      final rows = await storage.transactionRows();
      expect(rows.map((r) => r['id']), ['old-0', 'old-1']);
      expect(rows.firstWhere((r) => r['id'] == 'old-1')['amount'], 42);
    });

    test('deleting the same transaction twice at once is safe', () async {
      final storage = await storageWithHistory(2);
      final container = storage.container();
      await container.read(sqlitePrefsProvider.future);
      final notifier = container.read(homeNotifierProvider.notifier);

      await Future.wait([
        notifier.deleteTransaction('old-0'),
        notifier.deleteTransaction('old-0'),
      ]);

      expect((await storage.transactionRows()).map((r) => r['id']), ['old-1']);
      expect(container.read(homeNotifierProvider).transactions, hasLength(1));
    });
  });
}
