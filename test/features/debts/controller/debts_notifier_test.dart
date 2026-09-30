import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/debts/controller/debts/debts_notifier.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../../helpers/test_storage.dart';

const _key = 'debts_list_key_v2';

DebtModel _debt(String id) => DebtModel(
      id: id,
      personName: 'Asha',
      date: '01 September 2026',
      amount: 100,
      currency: 'INR',
      isOwed: true,
      iconName: 'debt',
    );

String _encode(List<Object> entries) => jsonEncode(
      entries.map((e) => e is DebtModel ? jsonEncode(e.toJson()) : e).toList(),
    );

Future<List<String>> _storedIds(TestStorage storage) async {
  final prefs = SqlitePrefs(storage.open());
  await prefs.init();
  final debts = await prefs.readJsonList(_key, DebtModel.fromJson);
  return debts.map((d) => d.id).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DebtsNotifier persistence', () {
    test('adding before the initial load finishes keeps stored debts',
        () async {
      final storage = TestStorage.create();
      await storage.putKeyValue(_key, _encode([_debt('a'), _debt('b')]));
      final container = storage.container();
      await container.read(sqlitePrefsProvider.future);

      await container.read(debtsNotifierProvider.notifier).addDebt(_debt('c'));

      expect(await _storedIds(storage), ['a', 'b', 'c']);
      expect(container.read(debtsNotifierProvider).debts, hasLength(3));
    });

    test('two quick adds are both saved', () async {
      final storage = TestStorage.create();
      final container = storage.container();
      await container.read(sqlitePrefsProvider.future);
      final notifier = container.read(debtsNotifierProvider.notifier);

      await Future.wait(
          [notifier.addDebt(_debt('x')), notifier.addDebt(_debt('y'))],);

      expect(await _storedIds(storage), ['x', 'y']);
    });

    test('an unreadable debt is preserved, not wiped, when saving', () async {
      final storage = TestStorage.create();
      await storage.putKeyValue(
        _key,
        _encode([_debt('a'), '{"id":"broken"}']),
      );
      final container = storage.container();
      final prefs = await container.read(sqlitePrefsProvider.future);

      await container.read(debtsNotifierProvider.notifier).addDebt(_debt('b'));

      expect(await _storedIds(storage), ['a', 'b']);
      expect(
        prefs.getStringList('$_key$unreadableKeySuffix'),
        ['{"id":"broken"}'],
      );
    });
  });
}
