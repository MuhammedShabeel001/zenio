import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});

class LocalDatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'zenio_money_tracker.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            date TEXT NOT NULL,
            amount REAL NOT NULL,
            currency TEXT NOT NULL,
            is_income INTEGER NOT NULL,
            note TEXT,
            bank_name TEXT,
            timestamp TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE key_value_store (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS key_value_store (
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
        }
      },
    );
  }

  // Generic methods
  Future<List<Map<String, dynamic>>> getTransactionsMap() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'timestamp DESC, date DESC');
  }

  Future<void> saveTransactionMap(Map<String, dynamic> tx) async {
    final db = await database;
    await db.insert(
      'transactions',
      tx,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTransactionMap(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveTransactionsList(List<Map<String, dynamic>> transactions) async {
    final db = await database;
    final batch = db.batch();
    // Since saveTransactionsList might be overriding the whole table, we might want to clear it first or just replace
    await db.delete('transactions');
    for (final tx in transactions) {
      batch.insert(
        'transactions',
        tx,
      );
    }
    await batch.commit(noResult: true);
  }

  // Key-Value Store generic methods
  Future<void> setKeyValue(String key, String value) async {
    final db = await database;
    await db.insert(
      'key_value_store',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getKeyValue(String key) async {
    final db = await database;
    final maps = await db.query(
      'key_value_store',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }
}
