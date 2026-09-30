import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../../helpers/test_storage.dart';

const _key = 'wallet_cards_list';

WalletCardModel _card(
  String id,
  String name, {
  double balance = 0,
}) =>
    WalletCardModel(
      id: id,
      bankName: name,
      cardNumber: '0000',
      cardType: 'Debit Card',
      gradientStartHex: '0xFF000000',
      gradientEndHex: '0xFF111111',
      balance: balance,
    );

TransactionModel _tx(String id, String bankName, double amount,
        {String? title,}) =>
    TransactionModel(
      id: id,
      title: title ?? 'Food',
      date: '01-09-2026',
      amount: amount,
      currency: 'INR',
      isIncome: false,
      bankName: bankName,
      timestamp: '26-09-01   10 : 00',
    );

/// Wallets as an older version of the app stored them: no opening balance.
Future<void> _seedLegacyWallets(
  TestStorage storage,
  List<WalletCardModel> cards,
) {
  return storage.putKeyValue(
    _key,
    jsonEncode([for (final c in cards) jsonEncode(c.toJson())]),
  );
}

Future<List<WalletCardModel>> _stored(TestStorage storage) async {
  final prefs = SqlitePrefs(storage.open());
  await prefs.init();
  return prefs.readJsonList(_key, WalletCardModel.fromJson);
}

Future<List<WalletCardModel>> _loadedWallets(
    ProviderContainer container,) async {
  await container.read(sqlitePrefsProvider.future);
  container.read(walletNotifierProvider);
  await container.read(walletNotifierProvider.notifier).loadWalletData();
  return container.read(walletNotifierProvider).cards;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('adding a wallet before the initial load keeps existing wallets',
      () async {
    final storage = TestStorage.create();
    await _seedLegacyWallets(storage, [_card('1', 'HDFC'), _card('2', 'SBI')]);
    final container = storage.container();
    await container.read(sqlitePrefsProvider.future);

    await container
        .read(walletNotifierProvider.notifier)
        .addCard(_card('3', 'Cash'), 250);

    final stored = await _stored(storage);
    expect(stored.map((c) => c.id), ['1', '2', '3']);
    expect(stored.last.openingBalance, 250);
  });

  group('migration to derived balances', () {
    test('keeps the balances users saw and backs up the old wallets', () async {
      final storage = TestStorage.create();
      final db = storage.open();
      await seedTransaction(db, _tx('t1', 'HDFC', 200));
      await seedTransaction(
        db,
        _tx('t2', 'HDFC -> SBI', 50, title: 'Transfer to SBI'),
      );
      await _seedLegacyWallets(storage, [
        _card('1', 'HDFC', balance: 500),
        _card('2', 'SBI', balance: 300),
      ]);

      final wallets = await _loadedWallets(storage.container());

      expect(wallets.map((c) => c.balance), [500, 300]);
      final stored = await _stored(storage);
      expect(stored.map((c) => c.openingBalance), [750, 250]);

      final prefs = SqlitePrefs(storage.open());
      await prefs.init();
      expect(
        prefs.containsKey('wallet_cards_list.before_opening_balances'),
        isTrue,
      );
    });

    test('running again changes nothing', () async {
      final storage = TestStorage.create();
      await seedTransaction(storage.open(), _tx('t1', 'HDFC', 200));
      await _seedLegacyWallets(storage, [_card('1', 'HDFC', balance: 500)]);
      await _loadedWallets(storage.container());

      final again = await _loadedWallets(storage.container());

      expect(again.single.balance, 500);
      expect((await _stored(storage)).single.openingBalance, 700);
    });
  });

  test(
      'a new wallet named like older transactions shows the balance typed '
      'for it', () async {
    final storage = TestStorage.create();
    // Transactions of a wallet deleted long ago.
    await seedTransaction(storage.open(), _tx('old', 'Cash', 5000));
    await _seedLegacyWallets(storage, [_card('1', 'HDFC', balance: 500)]);
    final container = storage.container();
    await _loadedWallets(container);

    await container
        .read(walletNotifierProvider.notifier)
        .addCard(_card('2', 'Cash'), 1000);
    await container.read(walletNotifierProvider.notifier).loadWalletData();

    final cash = container
        .read(walletNotifierProvider)
        .cards
        .firstWhere((c) => c.id == '2');
    expect(cash.balance, 1000);
  });

  group('derived balances', () {
    Future<ProviderContainer> migratedContainer(TestStorage storage) async {
      await seedTransaction(storage.open(), _tx('t1', 'HDFC', 200));
      await _seedLegacyWallets(storage, [_card('1', 'HDFC', balance: 500)]);
      final container = storage.container();
      await _loadedWallets(container);
      return container;
    }

    Future<double> balanceAfterChanges(ProviderContainer container) async {
      // Balances update from the transaction listener.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return container.read(walletNotifierProvider).cards.single.balance;
    }

    test('deleting a transaction gives the money back', () async {
      final storage = TestStorage.create();
      final container = await migratedContainer(storage);

      await container
          .read(homeNotifierProvider.notifier)
          .deleteTransaction('t1');

      expect(await balanceAfterChanges(container), 700);
    });

    test('editing a transaction amount updates the balance', () async {
      final storage = TestStorage.create();
      final container = await migratedContainer(storage);

      await container
          .read(homeNotifierProvider.notifier)
          .updateTransaction(_tx('t1', 'HDFC', 50));

      expect(await balanceAfterChanges(container), 650);
    });

    test('adjusting records an adjustment that is not income or spending',
        () async {
      final storage = TestStorage.create();
      final container = await migratedContainer(storage);
      final expenseBefore =
          container.read(homeNotifierProvider).summary?.expense;

      await container
          .read(walletNotifierProvider.notifier)
          .adjustBalance('1', 450);

      expect(await balanceAfterChanges(container), 450);
      final adjustment = container
          .read(homeNotifierProvider)
          .transactions
          .firstWhere((t) => t.kind == 'adjustment');
      expect(adjustment.amount, 50);
      expect(adjustment.isIncome, isFalse);
      expect(
          container.read(homeNotifierProvider).summary?.expense, expenseBefore,);
    });

    test('renaming a wallet keeps its transactions and balance', () async {
      final storage = TestStorage.create();
      final container = await migratedContainer(storage);

      await container.read(walletNotifierProvider.notifier).editCard(
            0,
            _card('1', 'HDFC Savings', balance: 12345),
          );

      expect(await balanceAfterChanges(container), 500);
      final rows = await storage.transactionRows();
      expect(rows.single['bank_name'], 'HDFC Savings');
      expect(
        container.read(walletNotifierProvider).cards.single.bankName,
        'HDFC Savings',
      );
    });
  });
}
