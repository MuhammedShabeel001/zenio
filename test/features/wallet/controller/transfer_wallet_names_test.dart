import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/implementations/money_tracker/money_tracker_repository.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/wallet_balances.dart';
import 'package:zenio/shared/services/csv_export_service.dart';
import 'package:zenio/shared/services/csv_import_service.dart';
import 'package:zenio/shared/services/local_database_service.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../../helpers/test_storage.dart';

const _main = 'Main';
const _savings = 'Savings -> Emergency';
const _personal = 'Personal -> Savings -> Emergency';

WalletCardModel _wallet(String name, double opening) => WalletCardModel(
      id: name,
      bankName: name,
      cardNumber: '',
      cardType: 'BANK',
      gradientStartHex: '0xFF000000',
      gradientEndHex: '0xFF111111',
      balance: opening,
      openingBalance: opening,
    );

TransactionModel _transfer(String id, String from, String to, double amount) =>
    TransactionModel(
      id: id,
      title: '$transferTitlePrefix$to',
      date: '10-09-2026',
      amount: amount,
      currency: 'INR',
      isIncome: false,
      bankName: transferBankName(from, to),
      timestamp: '26-09-10   09 : 00',
      kind: TransactionKind.transfer.name,
      transferFrom: from,
      transferTo: to,
    );

TransactionModel _expense(String id, String wallet, double amount) =>
    TransactionModel(
      id: id,
      title: 'Food',
      date: '10-09-2026',
      amount: amount,
      currency: 'INR',
      isIncome: false,
      bankName: wallet,
      timestamp: '26-09-10   09 : 00',
      kind: TransactionKind.expense.name,
    );

Map<String, double> _balances(
  List<WalletCardModel> wallets,
  List<TransactionModel> transactions,
) =>
    {
      for (final card in withDerivedBalances(wallets, transactions))
        card.bankName: card.balance,
    };

void main() {
  final wallets = [
    _wallet(_main, 1000),
    _wallet(_savings, 100),
    _wallet(_personal, 10),
  ];

  group('a wallet name containing "->" is never split', () {
    test('transfer from a normal wallet to one with "->"', () {
      expect(
        _balances(wallets, [_transfer('t', _main, _savings, 300)]),
        {_main: 700, _savings: 400, _personal: 10},
      );
    });

    test('transfer from a wallet with "->" to a normal wallet', () {
      expect(
        _balances(wallets, [_transfer('t', _savings, _main, 50)]),
        {_main: 1050, _savings: 50, _personal: 10},
      );
    });

    test('transfer between two wallets with "->", one of them twice', () {
      expect(
        _balances(wallets, [_transfer('t', _personal, _savings, 5)]),
        {_main: 1000, _savings: 105, _personal: 5},
      );
      expect(
        _balances(wallets, [_transfer('t', _savings, _personal, 20)]),
        {_main: 1000, _savings: 80, _personal: 30},
      );
    });

    test('spending from a wallet with "->" is not read as a transfer', () {
      final expense = _expense('e', _personal, 4);

      expect(expense.transferEnds, isNull);
      expect(
        _balances(wallets, [expense]),
        {_main: 1000, _savings: 100, _personal: 6},
      );
    });

    test('renaming keeps both ends of a transfer whole', () {
      final renamed = withWalletRenamed(
        [
          _transfer('t', _savings, _personal, 20),
          _expense('e', _personal, 4),
        ],
        _personal,
        'Rainy day',
      );

      expect(renamed.first.transferFrom, _savings);
      expect(renamed.first.transferTo, 'Rainy day');
      expect(renamed.first.bankName, '$_savings -> Rainy day');
      expect(renamed.first.title, 'Transfer to Rainy day');
      expect(renamed.last.bankName, 'Rainy day');
    });
  });

  group('transfers saved before the wallets were stored separately', () {
    TransactionModel legacy(String bankName, String title, {String? kind}) =>
        TransactionModel(
          id: bankName,
          title: title,
          date: '10-09-2026',
          amount: 100,
          currency: 'INR',
          isIncome: false,
          bankName: bankName,
          kind: kind,
        );

    test('are read from their wallet text as before', () {
      final old = legacy('HDFC -> Cash', 'Transfer to Cash');
      final newer =
          legacy('HDFC -> Cash', 'Transfer to Cash', kind: 'transfer');

      for (final tx in [old, newer]) {
        expect(tx.transferEnds, (from: 'HDFC', to: 'Cash'));
      }
      expect(
        _balances([_wallet('HDFC', 500), _wallet('Cash', 0)], [old]),
        {'HDFC': 400, 'Cash': 100},
      );
    });

    test('with several "->", the title says which wallet received it', () {
      final tx = legacy(
        '$_main -> $_savings',
        '$transferTitlePrefix$_savings',
        kind: 'transfer',
      );

      expect(tx.transferEnds, (from: _main, to: _savings));
    });
  });

  group('with the app', () {
    late TestStorage storage;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'Zenio',
        packageName: 'com.auren.zenio',
        version: '2.0.0',
        buildNumber: '2',
        buildSignature: '',
      );
      storage = TestStorage.create();
      await storage.putKeyValue(
        'wallet_cards_list',
        jsonEncode([for (final w in wallets) jsonEncode(w.toJson())]),
      );
      container = storage.container();
      await container.read(sqlitePrefsProvider.future);
      container.read(walletNotifierProvider);
      await container.read(walletNotifierProvider.notifier).loadWalletData();
    });

    Map<String, double> shown() => {
          for (final card in container.read(walletNotifierProvider).cards)
            card.bankName: card.balance,
        };

    Future<void> settled() =>
        container.read(walletNotifierProvider.notifier).idle();

    test('adding, editing and deleting such a transfer', () async {
      final home = container.read(homeNotifierProvider.notifier);

      await home.addTransaction(_transfer('t', _main, _personal, 300));
      await settled();
      expect(shown(), {_main: 700, _savings: 100, _personal: 310});

      // Edited to come from the other "->" wallet, and for less.
      await home.updateTransaction(
        _transfer('t', _savings, _personal, 40),
      );
      await settled();
      expect(shown(), {_main: 1000, _savings: 60, _personal: 50});

      await home.deleteTransaction('t');
      await settled();
      expect(shown(), {_main: 1000, _savings: 100, _personal: 10});
    });

    test('the stored wallets survive a restart', () async {
      await container
          .read(homeNotifierProvider.notifier)
          .addTransaction(_transfer('t', _personal, _savings, 5));
      await settled();

      final stored =
          await MoneyTrackerRepository(storage.open()).getTransactions();
      expect(stored.single.transferFrom, _personal);
      expect(stored.single.transferTo, _savings);
      expect(stored.single.bankName, '$_personal -> $_savings');
    });

    test('renaming a wallet with "->" moves only its own transactions',
        () async {
      final home = container.read(homeNotifierProvider.notifier);
      await home.addTransaction(_transfer('t', _savings, _personal, 20));
      await home.addTransaction(_expense('e', _personal, 4));
      await settled();

      final index = container
          .read(walletNotifierProvider)
          .cards
          .indexWhere((c) => c.bankName == _personal);
      final card = container.read(walletNotifierProvider).cards[index];
      await container
          .read(walletNotifierProvider.notifier)
          .editCard(index, card.copyWith(bankName: 'Rainy day'));
      await settled();

      expect(shown(), {_main: 1000, _savings: 80, 'Rainy day': 26});
      expect(
        container.read(walletNotifierProvider.notifier).transactionCountFor(
              index,
            ),
        2,
      );
      final stored = {
        for (final tx
            in await MoneyTrackerRepository(storage.open()).getTransactions())
          tx.id: tx,
      };
      expect(stored['t']!.transferTo, 'Rainy day');
      expect(stored['e']!.bankName, 'Rainy day');
    });

    test('an export of such transfers imports back into the same wallets',
        () async {
      final home = container.read(homeNotifierProvider.notifier);
      await home.addTransaction(_transfer('t1', _main, _savings, 300));
      await home.addTransaction(_transfer('t2', _personal, _main, 5));
      await settled();
      final csv = CsvExportService.buildCsv(
        await storage.open().getTransactionsMap(),
      );
      final before = shown();

      // A new install with the same wallets and their current balances.
      final target = TestStorage.create();
      await target.putKeyValue(
        'wallet_cards_list',
        jsonEncode([
          for (final entry in before.entries)
            jsonEncode(_wallet(entry.key, entry.value).toJson()),
        ]),
      );
      final other = target.container();
      await other.read(sqlitePrefsProvider.future);
      other.read(walletNotifierProvider);
      await other.read(walletNotifierProvider.notifier).loadWalletData();
      final plan = await CsvImportService(target.open())
          .planImport(csv, walletNames: before.keys);
      await other
          .read(walletNotifierProvider.notifier)
          .importTransactions(plan.transactions);

      final imported = {for (final tx in plan.transactions) tx.id: tx};
      expect(imported['t1']!.transferEnds, (from: _main, to: _savings));
      expect(imported['t2']!.transferEnds, (from: _personal, to: _main));
      expect(
        {
          for (final card in other.read(walletNotifierProvider).cards)
            card.bankName: card.balance,
        },
        before,
      );
    });
  });

  test('a database from before the transfer columns keeps its transfers',
      () async {
    final storage = TestStorage.create();
    // A version 3 database, as the app created it before this change.
    final path = '${(await storage.open().database).path}.v3';
    final v3 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE transactions (
              id TEXT PRIMARY KEY, title TEXT NOT NULL, date TEXT NOT NULL,
              amount REAL NOT NULL, currency TEXT NOT NULL,
              is_income INTEGER NOT NULL, note TEXT, bank_name TEXT,
              timestamp TEXT, kind TEXT
            )''');
          await db.execute(
            'CREATE TABLE key_value_store (key TEXT PRIMARY KEY, value TEXT)',
          );
        },
      ),
    );
    await v3.insert('transactions', {
      'id': 'old',
      'title': 'Transfer to Cash',
      'date': '01-09-2026',
      'amount': 250.0,
      'currency': 'INR',
      'is_income': 0,
      'bank_name': 'HDFC -> Cash',
      'kind': 'transfer',
    });
    await v3.close();
    addTearDown(() => databaseFactoryFfi.deleteDatabase(path));

    final upgraded =
        LocalDatabaseService(factory: databaseFactoryFfi, path: path);
    final transactions =
        await MoneyTrackerRepository(upgraded).getTransactions();

    final tx = transactions.single;
    expect(tx.transferFrom, isNull);
    expect(tx.transferEnds, (from: 'HDFC', to: 'Cash'));
    expect(
      _balances([_wallet('HDFC', 1000), _wallet('Cash', 0)], transactions),
      {'HDFC': 750, 'Cash': 250},
    );
    final columns = await (await upgraded.database)
        .rawQuery('PRAGMA table_info(transactions)');
    expect(
      columns.map((c) => c['name']),
      containsAll(['transfer_from', 'transfer_to']),
    );
  });
}
