import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/shared/services/local_database_service.dart';
import 'package:zenio/shared/utils/json_list_codec.dart';

final sqlitePrefsProvider = FutureProvider<SqlitePrefs>((ref) async {
  final dbService = ref.watch(localDatabaseServiceProvider);
  final prefs = SqlitePrefs(dbService);
  await prefs.init();
  return prefs;
});

/// Suffix of the key under which entries that could not be decoded are kept.
const String unreadableKeySuffix = '.unreadable';

class SqlitePrefs {
  SqlitePrefs(this._dbService);

  final LocalDatabaseService _dbService;
  final Map<String, String> _cache = {};

  Future<void> init() async {
    final db = await _dbService.database;
    final maps = await db.query('key_value_store');
    for (final map in maps) {
      final key = map['key'];
      final value = map['value'];
      if (key is String && value is String) {
        _cache[key] = value;
      }
    }
  }

  bool containsKey(String key) => _cache.containsKey(key);

  Future<void> setStringList(String key, List<String> value) async {
    final strVal = jsonEncode(value);
    await _dbService.setKeyValue(key, strVal);
    _cache[key] = strVal;
  }

  /// Stores [value] under [key] and inserts [transactions] in one database
  /// transaction (see [LocalDatabaseService.saveTransactionMapsAndKeyValue]),
  /// then caches [value]. Either both are stored or neither is.
  Future<void> setStringListWithTransactions(
    String key,
    List<String> value,
    List<Map<String, dynamic>> transactions,
  ) async {
    final strVal = jsonEncode(value);
    await _dbService.saveTransactionMapsAndKeyValue(
      transactions,
      key: key,
      value: strVal,
    );
    _cache[key] = strVal;
  }

  List<String>? getStringList(String key) {
    final val = _cache[key];
    if (val == null) return null;
    try {
      final decoded = jsonDecode(val) as List;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return null;
    }
  }

  /// Decodes the list of JSON objects stored under [key].
  ///
  /// Each entry is decoded on its own. Entries that fail are skipped and
  /// copied to `'$key$unreadableKeySuffix'`, so a later save of the readable
  /// entries can never destroy them. The value under [key] is not modified.
  Future<List<T>> readJsonList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final raw = _cache[key];
    if (raw == null) return [];
    final decoded = decodeJsonList(raw, fromJson);
    if (decoded.unreadable.isNotEmpty) {
      await _preserveUnreadable(key, decoded.unreadable);
    }
    return decoded.items;
  }

  /// Decodes the JSON object stored under [key], or returns null when it is
  /// missing. An undecodable value is preserved like in [readJsonList].
  Future<T?> readJsonObject<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final raw = _cache[key];
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await _preserveUnreadable(key, [raw]);
      return null;
    }
  }

  Future<void> _preserveUnreadable(String key, List<String> entries) async {
    if (kDebugMode) {
      debugPrint('SqlitePrefs: ${entries.length} unreadable value(s) under '
          '"$key"; kept under "$key$unreadableKeySuffix".');
    }
    final backupKey = '$key$unreadableKeySuffix';
    final existing = _cache[backupKey];
    final merged = mergeUnreadable(
      existing == null ? const [] : decodeStringList(existing),
      entries,
    );
    if (merged != null) await setStringList(backupKey, merged);
  }

  Future<void> setString(String key, String value) async {
    await _dbService.setKeyValue(key, value);
    _cache[key] = value;
  }

  String? getString(String key) {
    return _cache[key];
  }

  Future<void> setDouble(String key, double value) async {
    await _dbService.setKeyValue(key, value.toString());
    _cache[key] = value.toString();
  }

  double? getDouble(String key) {
    final val = _cache[key];
    if (val == null) return null;
    return double.tryParse(val);
  }

  Future<void> setBool(String key, bool value) async {
    await _dbService.setKeyValue(key, value.toString());
    _cache[key] = value.toString();
  }

  bool? getBool(String key) {
    final val = _cache[key];
    if (val == null) return null;
    return val == 'true';
  }

  Future<void> setInt(String key, int value) async {
    await _dbService.setKeyValue(key, value.toString());
    _cache[key] = value.toString();
  }

  int? getInt(String key) {
    final val = _cache[key];
    if (val == null) return null;
    return int.tryParse(val);
  }

  Future<void> remove(String key) async {
    final db = await _dbService.database;
    await db.delete(
      'key_value_store',
      where: 'key = ?',
      whereArgs: [key],
    );
    _cache.remove(key);
  }

  Future<void> clear() async {
    final db = await _dbService.database;
    await db.delete('key_value_store');
    _cache.clear();
  }
}
