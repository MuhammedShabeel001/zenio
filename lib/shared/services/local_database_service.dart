import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:zenio/shared/utils/money_limits.dart';

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});

class LocalDatabaseService {
  /// [factory] and [path] exist so tests can run against an in-memory
  /// database. The app uses the platform factory and the default file.
  LocalDatabaseService({DatabaseFactory? factory, String? path})
      : _factory = factory,
        _path = path;

  static const String _transactionsTable = 'transactions';
  static const String _keyValueTable = 'key_value_store';

  final DatabaseFactory? _factory;
  final String? _path;
  Future<Database>? _database;

  /// Opens the database once. Concurrent callers share the same future, and a
  /// failed open is forgotten so the next call can retry.
  Future<Database> get database => _database ??= _openOnce();

  Future<Database> _openOnce() async {
    try {
      return await _initDatabase();
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    final factory = _factory ?? databaseFactory;
    final path = _path ??
        join(await factory.getDatabasesPath(), 'zenio_money_tracker.db');

    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_transactionsTable (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              date TEXT NOT NULL,
              amount REAL NOT NULL,
              currency TEXT NOT NULL,
              is_income INTEGER NOT NULL,
              note TEXT,
              bank_name TEXT,
              timestamp TEXT,
              kind TEXT,
              transfer_from TEXT,
              transfer_to TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE $_keyValueTable (
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS $_keyValueTable (
                key TEXT PRIMARY KEY,
                value TEXT
              )
            ''');
          }
          if (oldVersion < 3) {
            // Additive only: existing rows keep kind NULL, which is read
            // exactly as before (see resolveTransactionKind). Checked first
            // because after a downgrade the version drops but the column
            // stays, and adding it twice would fail.
            await _addColumnIfMissing(db, 'kind');
          }
          if (oldVersion < 4) {
            // Additive only: the source and destination wallet of a
            // transfer. Existing transfers keep them NULL and are read from
            // `bank_name` exactly as before (see transferWallets).
            await _addColumnIfMissing(db, 'transfer_from');
            await _addColumnIfMissing(db, 'transfer_to');
          }
        },
      ),
    );
  }

  static Future<void> _addColumnIfMissing(Database db, String column) async {
    final columns = await db.rawQuery('PRAGMA table_info($_transactionsTable)');
    if (!columns.any((c) => c['name'] == column)) {
      await db.execute(
        'ALTER TABLE $_transactionsTable ADD COLUMN $column TEXT',
      );
    }
  }

  /// Refuses a row whose amount is not a storable amount: NaN, an infinity
  /// or beyond [maxMoneyAmount] never reaches the database.
  static void _checkAmount(Map<String, dynamic> tx) {
    final amount = tx['amount'];
    if (amount is! num) {
      throw const InvalidAmountException('transaction amount');
    }
    checkStorableAmount(amount, 'transaction amount');
  }

  Future<List<Map<String, dynamic>>> getTransactionsMap() async {
    final db = await database;
    return db.query(
      _transactionsTable,
      orderBy: 'timestamp DESC, date DESC',
    );
  }

  /// Inserts a new transaction. Fails instead of overwriting when a row with
  /// the same id already exists.
  Future<void> insertTransactionMap(Map<String, dynamic> tx) async {
    _checkAmount(tx);
    final db = await database;
    await db.insert(
      _transactionsTable,
      tx,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Updates the row with the same id. Returns the number of rows changed.
  Future<int> updateTransactionMap(Map<String, dynamic> tx) async {
    _checkAmount(tx);
    final db = await database;
    return db.update(
      _transactionsTable,
      tx,
      where: 'id = ?',
      whereArgs: [tx['id']],
    );
  }

  /// Inserts [transactions] in one database transaction: either every row is
  /// written or none is. Fails (writing nothing) if any row is invalid or its
  /// id already exists, so existing transactions are never overwritten.
  Future<void> saveTransactionMaps(
    List<Map<String, dynamic>> transactions,
  ) async {
    if (transactions.isEmpty) return;
    transactions.forEach(_checkAmount);
    final db = await database;
    await db.transaction((txn) async {
      await _insertAll(txn, transactions);
    });
  }

  /// Inserts [transactions] and stores [value] under [key] in one database
  /// transaction: either all of it is written or none of it. Fails (writing
  /// nothing) if any row's amount is not storable or its id already exists.
  Future<void> saveTransactionMapsAndKeyValue(
    List<Map<String, dynamic>> transactions, {
    required String key,
    required String value,
  }) async {
    transactions.forEach(_checkAmount);
    final db = await database;
    await db.transaction((txn) async {
      await _insertAll(txn, transactions);
      await txn.insert(
        _keyValueTable,
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  static Future<void> _insertAll(
    Transaction txn,
    List<Map<String, dynamic>> transactions,
  ) async {
    final batch = txn.batch();
    for (final tx in transactions) {
      batch.insert(
        _transactionsTable,
        tx,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Applies [change] to every transaction row in one database transaction.
  /// [change] returns the columns to update for a row, or null to skip it.
  /// Returns the number of rows updated.
  Future<int> updateTransactionRows(
    Map<String, Object?>? Function(Map<String, Object?> row) change,
  ) async {
    final db = await database;
    return db.transaction((txn) async {
      final rows = await txn.query(_transactionsTable);
      final batch = txn.batch();
      var updated = 0;
      for (final row in rows) {
        final values = change(row);
        if (values == null) continue;
        batch.update(
          _transactionsTable,
          values,
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        updated++;
      }
      await batch.commit(noResult: true);
      return updated;
    });
  }

  Future<void> deleteTransactionMap(String id) async {
    final db = await database;
    await db.delete(
      _transactionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setKeyValue(String key, String value) async {
    final db = await database;
    await db.insert(
      _keyValueTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Rebuilds the database file so that deleted values no longer linger in
  /// free pages. Used after removing sensitive data.
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  /// Wipes all tables from the local SQLite database in one transaction.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_transactionsTable);
      await txn.delete(_keyValueTable);
    });
  }
}
