import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/shared/services/local_database_service.dart';
import 'package:zenio/shared/providers/providers.dart';

final sqlitePrefsProvider = FutureProvider<SqlitePrefs>((ref) async {
  final dbService = ref.watch(localDatabaseServiceProvider);
  final prefs = SqlitePrefs(dbService);
  await prefs.init();
  return prefs;
});

class SqlitePrefs {
  final LocalDatabaseService _dbService;
  final Map<String, String> _cache = {};

  SqlitePrefs(this._dbService);

  Future<void> init() async {
    final db = await _dbService.database;
    final maps = await db.query('key_value_store');
    for (final map in maps) {
      _cache[map['key'] as String] = map['value'] as String;
    }
  }

  Future<void> setStringList(String key, List<String> value) async {
    final strVal = jsonEncode(value);
    _cache[key] = strVal;
    await _dbService.setKeyValue(key, strVal);
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

  Future<void> setString(String key, String value) async {
    _cache[key] = value;
    await _dbService.setKeyValue(key, value);
  }

  String? getString(String key) {
    return _cache[key];
  }

  Future<void> setDouble(String key, double value) async {
    _cache[key] = value.toString();
    await _dbService.setKeyValue(key, value.toString());
  }

  double? getDouble(String key) {
    final val = _cache[key];
    if (val == null) return null;
    return double.tryParse(val);
  }

  Future<void> setBool(String key, bool value) async {
    _cache[key] = value.toString();
    await _dbService.setKeyValue(key, value.toString());
  }

  bool? getBool(String key) {
    final val = _cache[key];
    if (val == null) return null;
    return val == 'true';
  }

  Future<void> setInt(String key, int value) async {
    _cache[key] = value.toString();
    await _dbService.setKeyValue(key, value.toString());
  }

  int? getInt(String key) {
    final val = _cache[key];
    if (val == null) return null;
    return int.tryParse(val);
  }

  Future<void> remove(String key) async {
    _cache.remove(key);
    final db = await _dbService.database;
    await db.delete(
      'key_value_store',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<void> clear() async {
    _cache.clear();
    final db = await _dbService.database;
    await db.delete('key_value_store');
  }
}
