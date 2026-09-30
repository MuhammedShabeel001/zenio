import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/shared/services/local_database_service.dart';

/// A real SQLite database in a temporary directory, for tests that need to
/// check what actually ends up on disk.
class TestStorage {
  TestStorage._(this._directory);

  /// Creates an empty database and removes it when the test ends.
  factory TestStorage.create() {
    if (!_ffiReady) {
      sqfliteFfiInit();
      _ffiReady = true;
    }
    final storage =
        TestStorage._(Directory.systemTemp.createTempSync('zenio_test_'));
    addTearDown(storage._dispose);
    return storage;
  }

  static bool _ffiReady = false;

  final Directory _directory;

  String get _path => '${_directory.path}/zenio.db';

  /// A service over this database, as the app would create it on launch.
  LocalDatabaseService open() {
    return LocalDatabaseService(factory: databaseFactoryFfi, path: _path);
  }

  /// A provider container that uses a fresh service over this database.
  ProviderContainer container({List<Override> overrides = const []}) {
    final container = ProviderContainer(
      overrides: [
        localDatabaseServiceProvider.overrideWithValue(open()),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Inserts a key/value row exactly as it would be stored on disk.
  Future<void> putKeyValue(String key, String value) {
    return open().setKeyValue(key, value);
  }

  /// Every row of the transactions table, including unreadable ones.
  Future<List<Map<String, Object?>>> transactionRows() async {
    final db = await open().database;
    return db.query('transactions', orderBy: 'id');
  }

  Future<void> _dispose() async {
    await databaseFactoryFfi.deleteDatabase(_path);
    if (_directory.existsSync()) {
      _directory.deleteSync(recursive: true);
    }
  }
}

/// Stores [transaction] the same way the app does.
Future<void> seedTransaction(
  LocalDatabaseService db,
  TransactionModel transaction,
) {
  return db.insertTransactionMap({
    ...transaction.toJson(),
    'is_income': transaction.isIncome ? 1 : 0,
  });
}

TransactionModel sampleTransaction(String id, {double amount = 100}) {
  return TransactionModel(
    id: id,
    title: 'Food',
    date: '15-09-2026',
    amount: amount,
    currency: 'INR',
    isIncome: false,
    bankName: 'HDFC',
    timestamp: '26-09-15   10 : 00',
  );
}
