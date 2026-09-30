import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenio/shared/services/local_database_service.dart';

import '../../helpers/test_storage.dart';

void main() {
  group('LocalDatabaseService', () {
    test('a failed bulk save writes nothing and keeps existing rows', () async {
      final storage = TestStorage.create();
      final db = storage.open();
      await seedTransaction(db, sampleTransaction('existing'));

      final valid = {
        ...sampleTransaction('new-1').toJson(),
        'is_income': 0,
      };
      // title is NOT NULL, so this row makes the whole batch fail.
      final invalid = {
        ...sampleTransaction('new-2').toJson(),
        'is_income': 0,
        'title': null,
      };

      await expectLater(
        db.saveTransactionMaps([valid, invalid]),
        throwsA(anything),
      );

      final rows = await storage.transactionRows();
      expect(rows.map((r) => r['id']), ['existing']);
    });

    test('inserting a duplicate id fails instead of overwriting', () async {
      final storage = TestStorage.create();
      final db = storage.open();
      await seedTransaction(db, sampleTransaction('tx', amount: 10));

      await expectLater(
        seedTransaction(db, sampleTransaction('tx', amount: 999)),
        throwsA(anything),
      );

      final rows = await storage.transactionRows();
      expect(rows.single['amount'], 10);
    });

    test('deleting the same row twice at once does not throw', () async {
      final storage = TestStorage.create();
      final db = storage.open();
      await seedTransaction(db, sampleTransaction('a'));
      await seedTransaction(db, sampleTransaction('b'));

      await Future.wait([
        db.deleteTransactionMap('a'),
        db.deleteTransactionMap('a'),
      ]);

      final rows = await storage.transactionRows();
      expect(rows.map((r) => r['id']), ['b']);
    });

    test('concurrent first opens share one database', () async {
      final storage = TestStorage.create();
      final db = storage.open();

      final opened = await Future.wait([db.database, db.database]);

      expect(identical(opened[0], opened[1]), isTrue);
    });

    test('upgrading from version 2 keeps every row and adds kind', () async {
      TestStorage.create(); // Initialises sqflite for this isolate.
      final dir = Directory.systemTemp.createTempSync('zenio_upgrade_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = '${dir.path}/v2.db';

      // The schema and data an existing install has on disk.
      final v2 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE transactions (id TEXT PRIMARY KEY, title TEXT NOT '
              'NULL, date TEXT NOT NULL, amount REAL NOT NULL, currency TEXT '
              'NOT NULL, is_income INTEGER NOT NULL, note TEXT, bank_name '
              'TEXT, timestamp TEXT)',
            );
            await db.execute(
              'CREATE TABLE key_value_store (key TEXT PRIMARY KEY, value TEXT)',
            );
          },
        ),
      );
      await v2.insert('transactions', {
        'id': 'kept',
        'title': 'Food',
        'date': '01-09-2026',
        'amount': 12.5,
        'currency': 'INR',
        'is_income': 0,
        'bank_name': 'HDFC',
      });
      await v2.insert('key_value_store', {'key': 'k', 'value': 'v'});
      await v2.close();

      final upgraded = await LocalDatabaseService(
        factory: databaseFactoryFfi,
        path: path,
      ).database;

      expect(await upgraded.getVersion(), 3);
      final rows = await upgraded.query('transactions');
      expect(rows.single['id'], 'kept');
      expect(rows.single['amount'], 12.5);
      expect(rows.single.containsKey('kind'), isTrue);
      expect(rows.single['kind'], isNull);
      expect(await upgraded.query('key_value_store'), hasLength(1));
      await upgraded.close();
    });
  });
}
