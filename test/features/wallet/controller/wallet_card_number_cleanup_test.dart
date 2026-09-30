import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/repositories/implementations/wallet_repository.dart';
import 'package:zenio/features/wallet/domain/wallet_kind.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../../helpers/test_storage.dart';

const _key = 'wallet_cards_list';
const _backupKey = 'wallet_cards_list.before_opening_balances';

/// A stored wallet, as the app saves it.
String _wallet(
  String id,
  String number, {
  String name = 'Wallet',
  String type = 'DEBIT CARD',
}) =>
    jsonEncode(
      WalletCardModel(
        id: id,
        bankName: name,
        cardNumber: number,
        cardType: type,
        gradientStartHex: 'image:assets/images/card_001.png',
        gradientEndHex: 'image:assets/images/card_001.png',
        balance: 1250.5,
        openingBalance: 1000,
        createdAt: 'September 2, 2026',
      ).toJson(),
    );

Future<SqlitePrefs> _prefs(TestStorage storage) async {
  final prefs = SqlitePrefs(storage.open());
  await prefs.init();
  return prefs;
}

/// The stored wallet list (or the copy under [key]), read back from disk.
Future<String?> _storedRaw(TestStorage storage, [String key = _key]) async =>
    (await _prefs(storage)).getString(key);

Future<List<Object?>> _storedEntries(
  TestStorage storage, [
  String key = _key,
]) async =>
    jsonDecode((await _storedRaw(storage, key))!) as List<Object?>;

Map<String, dynamic> _fields(Object? entry) =>
    jsonDecode(entry! as String) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('clearing made-up card numbers', () {
    test('clears both formats Zenio generated, and nothing else in them',
        () async {
      final storage = TestStorage.create();
      final entries = [
        _wallet('a', '4821  1093  7702  5518', type: 'CREDIT CARD'),
        _wallet('b', '**** **** **** 5518'),
      ];
      await storage.putKeyValue(_key, jsonEncode(entries));

      final cleared = await WalletRepository(await _prefs(storage))
          .clearGeneratedCardNumbers();

      expect(cleared, 2);
      final stored = await _storedEntries(storage);
      for (var i = 0; i < entries.length; i++) {
        expect(_fields(stored[i])['card_number'], '');
        // Every other field exactly as it was.
        expect(
          {..._fields(stored[i])}..remove('card_number'),
          {..._fields(entries[i])}..remove('card_number'),
        );
      }
    });

    test('keeps numbers users entered and other text exactly as stored',
        () async {
      final storage = TestStorage.create();
      final kept = [
        _wallet('1', '4111111111111234'), // digits, as the field takes them
        _wallet('2', '5678'),
        _wallet('3', '4821 1093 7702 5518'), // one space: not generated
        _wallet('4', '0123  4567  8901  2345'), // a group Zenio never made
        _wallet('5', '****  ****  ****  ****'), // an old placeholder
        _wallet('6', ''),
        // The shape elsewhere than the card number is left alone.
        _wallet('7', '9876', name: '4821  1093  7702  5518'),
      ];
      final raw = jsonEncode(kept);
      await storage.putKeyValue(_key, raw);

      final cleared = await WalletRepository(await _prefs(storage))
          .clearGeneratedCardNumbers();

      expect(cleared, 0);
      expect(await _storedRaw(storage), raw);
    });

    test('a second run changes nothing', () async {
      final storage = TestStorage.create();
      await storage.putKeyValue(
        _key,
        jsonEncode([
          _wallet('a', '4821  1093  7702  5518'),
          _wallet('b', '4111111111111234'),
        ]),
      );
      final prefs = await _prefs(storage);
      await WalletRepository(prefs).clearGeneratedCardNumbers();
      final afterFirst = await _storedRaw(storage);

      final cleared = await WalletRepository(await _prefs(storage))
          .clearGeneratedCardNumbers();

      expect(cleared, 0);
      expect(await _storedRaw(storage), afterFirst);
      expect(
        (await _storedEntries(storage)).map((e) => _fields(e)['card_number']),
        ['', '4111111111111234'],
      );
    });

    test('keeps older map entries as maps and unreadable entries as they are',
        () async {
      final storage = TestStorage.create();
      final legacy = jsonDecode(_wallet('m', '**** **** **** 4821'));
      await storage.putKeyValue(
        _key,
        jsonEncode([legacy, 'not a wallet', _wallet('b', '1234')]),
      );

      final cleared = await WalletRepository(await _prefs(storage))
          .clearGeneratedCardNumbers();

      expect(cleared, 1);
      final stored = await _storedEntries(storage);
      expect((stored[0]! as Map)['card_number'], '');
      expect(stored[1], 'not a wallet');
      expect(stored[2], _wallet('b', '1234'));
    });

    test('clears the copy kept from before opening balances the same way',
        () async {
      final storage = TestStorage.create();
      final backup = [
        _wallet('a', '4821  1093  7702  5518'),
        _wallet('b', '4111111111111234'),
        _wallet('c', '5678'),
      ];
      await storage.putKeyValue(_backupKey, jsonEncode(backup));

      final cleared = await WalletRepository(await _prefs(storage))
          .clearGeneratedCardNumbers();

      expect(cleared, 1);
      final stored = await _storedEntries(storage, _backupKey);
      expect(
        stored.map((e) => _fields(e)['card_number']),
        ['', '4111111111111234', '5678'],
      );
      // Its balances and every other field exactly as they were.
      expect(
        {..._fields(stored[0])}..remove('card_number'),
        {..._fields(backup[0])}..remove('card_number'),
      );
      expect(stored.sublist(1), backup.sublist(1));

      // A second run leaves it as it is.
      final afterFirst = await _storedRaw(storage, _backupKey);
      expect(
        await WalletRepository(await _prefs(storage))
            .clearGeneratedCardNumbers(),
        0,
      );
      expect(await _storedRaw(storage, _backupKey), afterFirst);
      // No wallet list is made up where there was none.
      expect(await _storedRaw(storage), isNull);
    });

    test('with no wallets stored, nothing is written', () async {
      final storage = TestStorage.create();

      final cleared = await WalletRepository(await _prefs(storage))
          .clearGeneratedCardNumbers();

      expect(cleared, 0);
      expect(await _storedRaw(storage), isNull);
    });
  });

  group('on launch', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'Zenio',
        packageName: 'com.aurea.zenio',
        version: '2.0.0',
        buildNumber: '2',
        buildSignature: '',
      );
    });

    test('the wallets load as before, without the made-up number, unlogged',
        () async {
      final logs = <String?>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) => logs.add(message);
      addTearDown(() => debugPrint = originalDebugPrint);

      final storage = TestStorage.create();
      await storage.putKeyValue(
        _key,
        jsonEncode([
          _wallet('a', '4821  1093  7702  5518', type: 'CREDIT CARD'),
          _wallet('b', '4111111111111234'),
        ]),
      );
      final container = storage.container();
      await container.read(sqlitePrefsProvider.future);
      container.read(walletNotifierProvider);
      await container.read(walletNotifierProvider.notifier).loadWalletData();

      final cards = container.read(walletNotifierProvider).cards;
      expect(cards.map((c) => c.id), ['a', 'b']);
      expect(cards.map((c) => c.balance), [1000, 1000]);
      // Shown exactly as before: no digits for the made-up number, the
      // last four for the entered one.
      expect(cards.map((c) => c.lastFour), [null, '1234']);
      expect(cards.first.cardNumber, '');
      expect(
        (await _storedEntries(storage)).map((e) => _fields(e)['card_number']),
        ['', '4111111111111234'],
      );
      expect(logs.where((l) => l != null && l.contains('4821')), isEmpty);
    });

    test('transactions and balances are exactly as before', () async {
      final storage = TestStorage.create();
      await storage.putKeyValue(
        _key,
        jsonEncode([
          _wallet(
            'a',
            '4821  1093  7702  5518',
            name: 'HDFC',
            type: 'CREDIT CARD',
          ),
          _wallet('b', '4111111111111234', name: 'Cash'),
        ]),
      );
      final db = storage.open();
      TransactionModel tx(
        String id,
        double amount, {
        required bool isIncome,
        required String kind,
        String bankName = 'HDFC',
        String? from,
        String? to,
      }) =>
          TransactionModel(
            id: id,
            title: id,
            date: '15-09-2026',
            amount: amount,
            currency: 'INR',
            isIncome: isIncome,
            bankName: bankName,
            timestamp: '26-09-15   10 : 00',
            kind: kind,
            transferFrom: from,
            transferTo: to,
          );
      for (final t in [
        tx('expense', 200, isIncome: false, kind: 'expense'),
        tx('income', 500, isIncome: true, kind: 'income', bankName: 'Cash'),
        tx(
          'transfer',
          100,
          isIncome: false,
          kind: 'transfer',
          bankName: 'HDFC -> Cash',
          from: 'HDFC',
          to: 'Cash',
        ),
        tx(
          'adjustment',
          50,
          isIncome: true,
          kind: 'adjustment',
          bankName: 'Cash',
        ),
      ]) {
        await seedTransaction(db, t);
      }
      final transactionsBefore = await storage.transactionRows();

      final container = storage.container();
      await container.read(sqlitePrefsProvider.future);
      container.read(walletNotifierProvider);
      await container.read(walletNotifierProvider.notifier).loadWalletData();

      expect(await storage.transactionRows(), transactionsBefore);
      final cards = container.read(walletNotifierProvider).cards;
      // HDFC: 1000 - 200 - 100 moved to Cash. Cash: 1000 + 500 + 100 + 50.
      expect(cards.map((c) => c.balance), [700, 1650]);
      expect(cards.map((c) => c.openingBalance), [1000, 1000]);
      expect(cards.map((c) => c.lastFour), [null, '1234']);
    });

    test('a wallet added before the first load is kept', () async {
      final storage = TestStorage.create();
      await storage.putKeyValue(
        _key,
        jsonEncode([_wallet('a', '4821  1093  7702  5518')]),
      );
      final container = storage.container();
      await container.read(sqlitePrefsProvider.future);

      await container.read(walletNotifierProvider.notifier).addCard(
            const WalletCardModel(
              id: 'b',
              bankName: 'Cash',
              cardNumber: '',
              cardType: 'CASH',
              gradientStartHex: '0xFF000000',
              gradientEndHex: '0xFF111111',
            ),
            250,
          );

      final stored = await _storedEntries(storage);
      expect(stored.map((e) => _fields(e)['id']), ['a', 'b']);
      expect(stored.map((e) => _fields(e)['card_number']), ['', '']);
    });
  });
}
