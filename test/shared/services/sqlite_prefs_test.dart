import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../helpers/test_storage.dart';

String _debtJson(String id) => jsonEncode(
      const DebtModel(
        id: 'placeholder',
        personName: 'Asha',
        date: '01 September 2026',
        amount: 250,
        currency: 'INR',
        isOwed: true,
        iconName: 'debt',
      ).copyWith(id: id).toJson(),
    );

void main() {
  const key = 'debts_list_key_v2';
  const unreadableKey = '$key$unreadableKeySuffix';

  Future<SqlitePrefs> prefsWith(TestStorage storage, String rawValue) async {
    await storage.putKeyValue(key, rawValue);
    final prefs = SqlitePrefs(storage.open());
    await prefs.init();
    return prefs;
  }

  group('SqlitePrefs.readJsonList', () {
    test('skips an unreadable entry and keeps the readable ones', () async {
      final storage = TestStorage.create();
      final stored = jsonEncode([
        _debtJson('a'),
        '{"id": "broken"}',
        _debtJson('b'),
      ]);
      final prefs = await prefsWith(storage, stored);

      final debts = await prefs.readJsonList(key, DebtModel.fromJson);

      expect(debts.map((d) => d.id), ['a', 'b']);
      // The stored list itself is untouched...
      expect(prefs.getString(key), stored);
      // ...and the unreadable entry is kept for recovery.
      expect(prefs.getStringList(unreadableKey), ['{"id": "broken"}']);
    });

    test('preserves a corrupt value instead of discarding it', () async {
      final storage = TestStorage.create();
      final prefs = await prefsWith(storage, 'not json');

      final debts = await prefs.readJsonList(key, DebtModel.fromJson);

      expect(debts, isEmpty);
      expect(prefs.getString(key), 'not json');
      expect(prefs.getStringList(unreadableKey), ['not json']);
    });

    test('reading twice does not duplicate preserved entries', () async {
      final storage = TestStorage.create();
      final prefs = await prefsWith(
        storage,
        jsonEncode([_debtJson('a'), '{"id": "broken"}']),
      );

      await prefs.readJsonList(key, DebtModel.fromJson);
      await prefs.readJsonList(key, DebtModel.fromJson);

      expect(prefs.getStringList(unreadableKey), hasLength(1));
    });

    test('preserved entries survive a restart', () async {
      final storage = TestStorage.create();
      final prefs = await prefsWith(
        storage,
        jsonEncode([_debtJson('a'), '{"id": "broken"}']),
      );
      await prefs.readJsonList(key, DebtModel.fromJson);

      final restarted = SqlitePrefs(storage.open());
      await restarted.init();

      expect(restarted.getStringList(unreadableKey), ['{"id": "broken"}']);
    });
  });
}
