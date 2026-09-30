import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/vault/controller/vault/vault_notifier.dart';
import 'package:zenio/features/vault/domain/models/vault_card_model.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';
import 'package:zenio/features/vault/domain/repositories/implementations/vault_repository.dart';
import 'package:zenio/shared/services/secure_key_value_store.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../helpers/test_storage.dart';

class FakeSecureStore implements SecureKeyValueStore {
  final Map<String, String> values = {};
  bool failWrites = false;
  bool failDeletes = false;
  bool corruptReads = false;

  @override
  Future<String?> read(String key) async {
    final value = values[key];
    return corruptReads && value != null ? '$value-corrupted' : value;
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw Exception('Keystore unavailable');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failDeletes) throw Exception('Keystore unavailable');
    values.remove(key);
  }

  @override
  Future<void> deleteAllForcibly() async => values.clear();
}

const _legacyCards = 'vault_cards_list_v2';
const _legacyNotes = 'vault_notes_list_v2';

VaultCardModel _card(String id) => VaultCardModel(
      id: id,
      cardType: 'Visa',
      cardNumber: '4242424242424242',
      expiry: '12/30',
      cvv: '123',
    );

String _legacyList(List<Map<String, dynamic>> items) =>
    jsonEncode(items.map(jsonEncode).toList());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestStorage storage;
  late FakeSecureStore secure;

  Future<void> seedLegacyVault() async {
    await storage.putKeyValue(
      _legacyCards,
      _legacyList([_card('a').toJson(), _card('b').toJson()]),
    );
    await storage.putKeyValue(
      _legacyNotes,
      _legacyList([
        const VaultNoteModel(id: 'n', date: '01 Sep 2026', content: 'pin 1234')
            .toJson(),
      ]),
    );
  }

  Future<SqlitePrefs> reloadPrefs() async {
    final prefs = SqlitePrefs(storage.open());
    await prefs.init();
    return prefs;
  }

  setUp(() {
    storage = TestStorage.create();
    secure = FakeSecureStore();
  });

  test('moves plain-text vault data into secure storage and deletes it',
      () async {
    await seedLegacyVault();
    final legacyCards = (await reloadPrefs()).getString(_legacyCards);
    final container = storage.container(
      overrides: [secureKeyValueStoreProvider.overrideWithValue(secure)],
    );
    await container.read(sqlitePrefsProvider.future);
    final repo = container.read(vaultRepositoryRepoProvider);

    final cards = await repo.getCards();
    final notes = await repo.getNotes();

    expect(cards.map((c) => c.id), ['a', 'b']);
    expect(cards.first.cvv, '123');
    expect(notes.single.content, 'pin 1234');
    expect(secure.values['vault.cards'], legacyCards);

    final prefs = await reloadPrefs();
    expect(prefs.containsKey(_legacyCards), isFalse);
    expect(prefs.containsKey(_legacyNotes), isFalse);
    expect(prefs.containsKey(VaultRepository.migratedMarkerKey), isTrue);
  });

  test('keeps the plain-text data when the secure copy cannot be verified',
      () async {
    await seedLegacyVault();
    secure.corruptReads = true;
    final container = storage.container(
      overrides: [secureKeyValueStoreProvider.overrideWithValue(secure)],
    );
    await container.read(sqlitePrefsProvider.future);

    final cards = await container.read(vaultRepositoryRepoProvider).getCards();

    expect(cards.map((c) => c.id), ['a', 'b']);
    final prefs = await reloadPrefs();
    expect(prefs.containsKey(_legacyCards), isTrue);
    expect(prefs.containsKey(VaultRepository.migratedMarkerKey), isFalse);
  });

  test(
      'when secure storage fails, existing data stays readable and removable '
      'but new card details are not written as plain text', () async {
    await seedLegacyVault();
    secure.failWrites = true;
    final container = storage.container(
      overrides: [secureKeyValueStoreProvider.overrideWithValue(secure)],
    );
    await container.read(sqlitePrefsProvider.future);
    final notifier = container.read(vaultNotifierProvider.notifier);

    await expectLater(
      notifier.addCard(_card('c')),
      throwsA(isA<VaultUnavailableException>()),
    );
    await notifier.deleteCard('a');

    final prefs = await reloadPrefs();
    final stored =
        await prefs.readJsonList(_legacyCards, VaultCardModel.fromJson);
    expect(stored.map((c) => c.id), ['b']);
  });

  test('clearing works even when the key store cannot delete', () async {
    await seedLegacyVault();
    final container = storage.container(
      overrides: [secureKeyValueStoreProvider.overrideWithValue(secure)],
    );
    await container.read(sqlitePrefsProvider.future);
    final repo = container.read(vaultRepositoryRepoProvider);
    await repo.getCards();
    secure.failDeletes = true;

    await repo.clearAll();

    expect(secure.values, isEmpty);
  });

  test('an interrupted move finishes on the next launch', () async {
    await seedLegacyVault();
    // A previous launch copied the cards but stopped before recording it.
    secure.values['vault.cards'] =
        (await reloadPrefs()).getString(_legacyCards)!;

    final container = storage.container(
      overrides: [secureKeyValueStoreProvider.overrideWithValue(secure)],
    );
    await container.read(sqlitePrefsProvider.future);
    final cards = await container.read(vaultRepositoryRepoProvider).getCards();

    expect(cards.map((c) => c.id), ['a', 'b']);
    expect((await reloadPrefs()).containsKey(_legacyCards), isFalse);
  });

  test('discards secure entries left over from an earlier install', () async {
    secure.values['vault.cards'] = _legacyList([_card('old').toJson()]);
    final container = storage.container(
      overrides: [secureKeyValueStoreProvider.overrideWithValue(secure)],
    );
    await container.read(sqlitePrefsProvider.future);

    final cards = await container.read(vaultRepositoryRepoProvider).getCards();

    expect(cards, isEmpty);
    expect(secure.values, isNot(contains('vault.cards')));
  });

  test('new cards are saved to secure storage only', () async {
    final container = storage.container(
      overrides: [secureKeyValueStoreProvider.overrideWithValue(secure)],
    );
    await container.read(sqlitePrefsProvider.future);

    await container.read(vaultNotifierProvider.notifier).addCard(_card('x'));

    expect(secure.values['vault.cards'], contains('4242424242424242'));
    final prefs = await reloadPrefs();
    expect(prefs.containsKey(_legacyCards), isFalse);
    final db = await storage.open().database;
    final rows = await db.query('key_value_store');
    expect(
      rows.any((r) => (r['value']! as String).contains('4242424242424242')),
      isFalse,
    );
  });

  test('clearAll removes the vault from secure storage', () async {
    await seedLegacyVault();
    final container = storage.container(
      overrides: [secureKeyValueStoreProvider.overrideWithValue(secure)],
    );
    await container.read(sqlitePrefsProvider.future);
    final repo = container.read(vaultRepositoryRepoProvider);
    await repo.getCards();

    await repo.clearAll();

    expect(secure.values, isEmpty);
    expect(await repo.getCards(), isEmpty);
  });
}
