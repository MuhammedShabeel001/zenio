import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/summary/financial_summary_model.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/implementations/money_tracker/money_tracker_repository.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/wallet_balances.dart';
import 'package:zenio/shared/providers/clock_provider/clock_provider.dart';
import 'package:zenio/shared/services/csv_export_service.dart';
import 'package:zenio/shared/services/csv_import_service.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../helpers/test_storage.dart';

void main() {
  group('export', () {
    test('escapes cells that spreadsheets would run as formulas', () {
      final csv = CsvExportService.buildCsv([
        {
          'id': '1',
          'title': '=HYPERLINK("http://evil")',
          'date': '01-09-2026',
          'amount': 10.5,
          'currency': 'INR',
          'is_income': 0,
          'bank_name': '@Wallet',
          'note': '+note, with comma',
        },
      ]);

      final row = csv.trim().split('\n').last;
      expect(row, contains('"\'=HYPERLINK(""http://evil"")"'));
      expect(row, contains("'@Wallet"));
      expect(row, contains('"\'+note, with comma"'));
      expect(row, contains(',10.5,'));
    });

    test('labels transfers and keeps the direction of adjustments', () {
      final csv = CsvExportService.buildCsv([
        {
          'id': 't',
          'title': 'Transfer to Cash',
          'date': '01-09-2026',
          'amount': 5,
          'currency': 'INR',
          'is_income': 0,
          'bank_name': 'HDFC -> Cash',
        },
        {
          'id': 'a',
          'title': 'Balance adjustment',
          'date': '01-09-2026',
          'amount': 7,
          'currency': 'INR',
          'is_income': 0,
          'bank_name': 'HDFC',
          'kind': 'adjustment',
        },
      ]);

      expect(csv, contains('01-09-2026,Transfer,Transfer to Cash,5,'));
      expect(csv, contains('01-09-2026,Adjustment,Balance adjustment,-7,'));
    });

    test('writes dates older versions stored in the importable format', () {
      final csv = CsvExportService.buildCsv([
        {
          'id': '1',
          'title': 'Food',
          'date': 'Thursday, September 17, 2026',
          'amount': 10,
          'currency': 'INR',
          'is_income': 0,
          'bank_name': 'HDFC',
        },
      ]);

      expect(csv, contains('\n17-09-2026,Expense,Food,10,'));
    });

    test('writes US dollars as USD; other currencies as stored', () {
      final csv = CsvExportService.buildCsv([
        {
          'id': 'd',
          'title': 'Food',
          'date': '01-09-2026',
          'amount': 10,
          'currency': 'DLR',
          'is_income': 0,
          'bank_name': 'Chase',
        },
        {
          'id': 'i',
          'title': 'Food',
          'date': '01-09-2026',
          'amount': 10,
          'currency': 'INR',
          'is_income': 0,
          'bank_name': 'HDFC',
        },
      ]);

      final lines = csv.trim().split('\n');
      // The columns are the same as before.
      expect(
        lines.first,
        'Date,Type,Category/Title,Amount,Currency,Wallet,Note,Transaction ID',
      );
      expect(lines[1], '01-09-2026,Expense,Food,10,USD,Chase,,d');
      expect(lines[2], '01-09-2026,Expense,Food,10,INR,HDFC,,i');
      expect(csv, isNot(contains('DLR')));
    });
  });

  group('import', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'Zenio',
        packageName: 'com.auren.zenio',
        version: '2.0.0',
        buildNumber: '2',
        buildSignature: '',
      );
    });

    test('a valid Zenio file imports every row with its meaning', () async {
      final app = await _App.create(wallets: {'HDFC': 1000, 'Cash': 200});

      final plan = await app.import(
        'Date,Type,Category/Title,Amount,Currency,Wallet,Note,Transaction ID\n'
        '15-09-2026,Expense,Food,120,INR,HDFC,lunch,e1\n'
        '16-09-2026,Income,Salary,"1,000.50",INR,HDFC,,i1\n'
        '17-09-2026,Transfer,Transfer to Cash,300,INR,HDFC -> Cash,,t1\n'
        '18-09-2026,Adjustment,Balance adjustment,-20,INR,Cash,,a1\n',
      );

      expect(plan.transactions, hasLength(4));
      final rows = await app.rowsById();
      expect(rows['e1']!['kind'], 'expense');
      expect(rows['e1']!['is_income'], 0);
      expect(rows['e1']!['note'], 'lunch');
      expect(rows['i1']!['kind'], 'income');
      expect(rows['i1']!['is_income'], 1);
      expect(rows['i1']!['amount'], 1000.5);
      expect(rows['t1']!['kind'], 'transfer');
      expect(rows['t1']!['transfer_from'], 'HDFC');
      expect(rows['t1']!['transfer_to'], 'Cash');
      expect(rows['a1']!['kind'], 'adjustment');
      expect(rows['a1']!['amount'], 20);
      expect(rows['a1']!['is_income'], 0);
      // Sorted by its own date rather than the day it was imported.
      expect(rows['e1']!['timestamp'], '26-09-15   10 : 15');
    });

    test('balances the user entered are kept: history is not counted twice',
        () async {
      // Restoring an export: the wallets were recreated with the balances
      // they have now, which already include this history.
      final app = await _App.create(wallets: {'HDFC': 15000, 'Cash': 500});

      await app.import(
        'Date,Type,Category/Title,Amount,Wallet,Transaction ID\n'
        '01-09-2026,Income,Salary,50000,HDFC,i1\n'
        '02-09-2026,Expense,Rent,45000,HDFC,e1\n'
        '03-09-2026,Transfer,Transfer to Cash,1000,HDFC -> Cash,t1\n',
      );

      expect(app.balances, {'HDFC': 15000, 'Cash': 500});
      expect(await app.storedBalances(), {'HDFC': 15000, 'Cash': 500});
      expect(await app.rowsById(), hasLength(3));
    });

    test('an export restores into recreated wallets exactly', () async {
      final source = await _App.create(
        wallets: {'HDFC': 10000, 'Cash': 0, 'Amex': -2000},
        transactions: [
          _tx('i1', 'Salary', 50000, 'HDFC', income: true, kind: 'income'),
          _tx('e1', 'Food', 1200, 'HDFC'),
          _tx('e2', 'Travel', 700, 'Amex'),
          _tx(
            't1',
            'Transfer to Cash',
            3000,
            'HDFC -> Cash',
            kind: 'transfer',
            from: 'HDFC',
            to: 'Cash',
          ),
          _tx(
            'a1',
            'Balance adjustment',
            500,
            'Cash',
            income: true,
            kind: 'adjustment',
          ),
        ],
      );
      final csv = CsvExportService.buildCsv(
        await source.storage.open().getTransactionsMap(),
      );

      // A new phone: the same wallets, entered with their current balances.
      final target = await _App.create(wallets: source.balances);
      await target.import(csv);

      expect(target.balances, source.balances);
      expect(await target.storedBalances(), source.balances);
      final before = await source.rowsById();
      final after = await target.rowsById();
      expect(after.keys, unorderedEquals(before.keys));
      for (final id in before.keys) {
        for (final column in [
          'title',
          'date',
          'amount',
          'is_income',
          'kind',
          'bank_name',
          'transfer_from',
          'transfer_to',
        ]) {
          expect(
            after[id]![column],
            before[id]![column],
            reason: '$id $column',
          );
        }
      }
      // Home's month and spending by category (as Analytics sums it).
      expect(target.summary.income, source.summary.income);
      expect(target.summary.expense, source.summary.expense);
      expect(target.spendingByTitle, source.spendingByTitle);
    });

    test('importing the same file again changes nothing', () async {
      final app = await _App.create(wallets: {'HDFC': 1000});
      const file = 'Date,Type,Category,Amount,Wallet\n'
          '15-09-2026,Expense,Food,120,HDFC\n'
          '16-09-2026,Expense,Taxi,80,HDFC\n';

      final first = await app.import(file);
      final second = await app.import(file);

      expect(first.transactions, hasLength(2));
      expect(second.transactions, isEmpty);
      expect(second.alreadyPresent, 2);
      expect(await app.rowsById(), hasLength(2));
      expect(app.balances, {'HDFC': 1000});
    });

    test('a file without a Type column is rejected', () async {
      final app = await _App.create(wallets: {'HDFC': 1000});

      await app.expectRejected(
        'Date,Category,Amount,Wallet\n15-09-2026,Food,120,HDFC\n',
        contains('no Type column'),
      );
    });

    test('a row without a type, or with an unknown one, is rejected', () async {
      final app = await _App.create(wallets: {'HDFC': 1000});

      await app.expectRejected(
        'Date,Type,Category,Amount,Wallet\n15-09-2026,,Food,120,HDFC\n',
        contains('Row 2 has no Type'),
      );
      await app.expectRejected(
        'Date,Type,Category,Amount,Wallet\n15-09-2026,Credit,Food,120,HDFC\n',
        contains('Type "Credit" isn\'t Expense, Income, Transfer or '
            'Adjustment'),
      );
    });

    test('a wallet Zenio does not have is rejected, naming it', () async {
      final app = await _App.create(wallets: {'HDFC': 1000});

      await app.expectRejected(
        'Date,Type,Category,Amount,Wallet\n'
        '15-09-2026,Expense,Food,120,HDFC\n'
        '16-09-2026,Expense,Taxi,80,Paytm\n',
        contains('no wallet named "Paytm"'),
      );
      await app.expectRejected(
        'Date,Type,Category,Amount,Wallet\n'
        '15-09-2026,Transfer,Transfer to Paytm,120,HDFC -> Paytm\n',
        contains('no wallet named "Paytm"'),
      );
      await app.expectRejected(
        'Date,Type,Category,Amount,Wallet\n15-09-2026,Expense,Food,120,\n',
        contains('Row 2 has no wallet'),
      );
    });

    test('ambiguous amounts are rejected rather than guessed', () async {
      final app = await _App.create(wallets: {'HDFC': 1000});

      for (final (amount, message) in [
        ('"1.234,50"', "isn't an amount"),
        ('"12,5"', "isn't an amount"),
        ('.5', "isn't an amount"),
        ('-120', 'only Adjustment rows can have a negative amount'),
        ('0', 'the amount is zero'),
        ('12.345', 'at most two decimal places'),
        ('9' * 400, 'larger than Zenio can store'),
        ('9999999999999', 'larger than Zenio can store'),
      ]) {
        await app.expectRejected(
          'Date,Type,Category,Amount,Wallet\n'
          '15-09-2026,Expense,Food,$amount,HDFC\n',
          contains(message),
        );
      }
    });

    test('amounts written with a currency are still read', () async {
      final app = await _App.create(wallets: {'HDFC': 1000});

      await app.import(
        'Date,Type,Category,Amount,Wallet\n'
        '15-09-2026,Expense,Largest,999999999999.99,HDFC\n'
        '15-09-2026,Expense,Rupees dot,Rs. 500,HDFC\n'
        '15-09-2026,Expense,Rupees no space,"Rs.1,00,000",HDFC\n'
        '15-09-2026,Expense,Symbol,"₹ 1,234.50",HDFC\n'
        '15-09-2026,Adjustment,Down,-₹ 20,HDFC\n',
      );

      final rows = {
        for (final r in (await app.rowsById()).values) r['title']: r,
      };
      expect(rows['Largest']!['amount'], 999999999999.99);
      expect(rows['Rupees dot']!['amount'], 500);
      expect(rows['Rupees no space']!['amount'], 100000);
      expect(rows['Symbol']!['amount'], 1234.5);
      expect(rows['Down']!['amount'], 20);
      expect(rows['Down']!['is_income'], 0);
    });

    test('one bad row rejects the whole file and changes nothing', () async {
      final app = await _App.create(
        wallets: {'HDFC': 1000},
        transactions: [_tx('old', 'Food', 100, 'HDFC')],
      );
      final balancesBefore = app.balances;
      final rowsBefore = await app.rowsById();
      final valid = [
        for (var i = 0; i < 500; i++) '15-09-2026,Expense,Food,1,HDFC,r$i',
      ];

      await app.expectRejected(
        'Date,Type,Category,Amount,Wallet,Transaction ID\n'
        '${valid.join('\n')}\n'
        '12/31/2025,Expense,US date,50,HDFC,bad\n',
        contains('Row 502'),
      );

      expect(app.balances, balancesBefore);
      expect(await app.storedBalances(), balancesBefore);
      expect(await app.rowsById(), rowsBefore);
    });

    test('a failure while saving leaves no partial import', () async {
      final app = await _App.create(wallets: {'HDFC': 1000});
      final plan = await app.plan(
        'Date,Type,Category,Amount,Wallet,Transaction ID\n'
        '15-09-2026,Expense,Food,120,HDFC,x1\n'
        '16-09-2026,Expense,Taxi,80,HDFC,x2\n',
      );
      // Another write takes one of the ids after the file was checked.
      await seedTransaction(app.storage.open(), _tx('x2', 'Other', 5, 'HDFC'));
      final storedBefore = await app.storedWalletsJson();

      await expectLater(
        app.container
            .read(walletNotifierProvider.notifier)
            .importTransactions(plan.transactions),
        throwsA(anything),
      );

      expect((await app.rowsById()).keys, ['x2']);
      expect(await app.storedWalletsJson(), storedBefore);
    });

    test('a repeated transaction ID or an unclosed quote is rejected',
        () async {
      final app = await _App.create(wallets: {'HDFC': 1000});

      await app.expectRejected(
        'Date,Type,Category,Amount,Wallet,Transaction ID\n'
        '15-09-2026,Expense,Food,120,HDFC,1.75921E+12\n'
        '16-09-2026,Expense,Rent,900,HDFC,1.75921E+12\n',
        contains('same Transaction ID as an earlier row'),
      );
      await app.expectRejected(
        'Date,Type,Category,Amount,Wallet\n'
        '15-09-2026,Expense,"Food,120,HDFC\n'
        '16-09-2026,Expense,Rent,900,HDFC\n',
        contains('never closed'),
      );
    });

    test('reads the long dates older versions stored', () async {
      final app = await _App.create(wallets: {'HDFC': 1000});

      await app.import(
        'Date,Type,Category,Amount,Wallet\n'
        '"Thursday, September 17, 2026",Expense,Food,10,HDFC\n'
        '"September 18, 2026",Expense,Taxi,20,HDFC\n',
      );

      final dates = (await app.rowsById()).values.map((r) => r['date']);
      expect(dates, containsAll(['17-09-2026', '18-09-2026']));
    });

    test('reads a first row of data as data', () async {
      final app = await _App.create(wallets: {'HDFC': 1000});

      // "Candidate" contains "date" but is not a header.
      final plan =
          await app.import('15-09-2026,Expense,Candidate fee,99,,HDFC\n');

      expect(plan.transactions.single.title, 'Candidate fee');
      expect(plan.transactions.single.amount, 99);
    });

    test('files with the same row ids do not overwrite each other', () async {
      final app = await _App.create(wallets: {'HDFC': 1000});

      await app.import(
        'ID,Date,Type,Category,Amount,Wallet\n'
        '1,15-09-2026,Expense,Food,120,HDFC\n',
      );
      await app.import(
        'ID,Date,Type,Category,Amount,Wallet\n'
        '1,16-09-2026,Expense,Rent,900,HDFC\n',
      );

      final titles = (await app.rowsById()).values.map((r) => r['title']);
      expect(titles, containsAll(['Food', 'Rent']));
    });

    test('a dollar export imports and exports again the same', () async {
      final source = await _App.create(
        wallets: {'Chase': 100},
        transactions: [_tx('d1', 'Food', 12.5, 'Chase', currency: 'DLR')],
      );
      final csv = CsvExportService.buildCsv(
        await source.storage.open().getTransactionsMap(),
      );

      final target = await _App.create(wallets: {'Chase': 100});
      await target.import(csv);

      expect(
        CsvExportService.buildCsv(
          await target.storage.open().getTransactionsMap(),
        ),
        csv,
      );
    });
  });
}

/// A Zenio install on a real database: [create] stores wallets (by name,
/// with their opening balance) and transactions, then loads them.
class _App {
  _App._(this.storage, this.container);

  final TestStorage storage;
  final ProviderContainer container;

  static final DateTime _now = DateTime(2026, 9, 30, 10, 15);

  static Future<_App> create({
    Map<String, double> wallets = const {},
    List<TransactionModel> transactions = const [],
  }) async {
    final storage = TestStorage.create();
    await storage.putKeyValue(
      'wallet_cards_list',
      jsonEncode([
        for (final entry in wallets.entries)
          jsonEncode(
            WalletCardModel(
              id: entry.key,
              bankName: entry.key,
              cardNumber: '',
              cardType: entry.value < 0 ? 'CREDIT CARD' : 'BANK',
              gradientStartHex: '0xFF000000',
              gradientEndHex: '0xFF111111',
              balance: entry.value,
              openingBalance: entry.value,
            ).toJson(),
          ),
      ]),
    );
    final db = storage.open();
    for (final tx in transactions) {
      await seedTransaction(db, tx);
    }
    final container = storage.container(
      overrides: [clockProvider.overrideWithValue(() => _now)],
    );
    await container.read(sqlitePrefsProvider.future);
    container.read(walletNotifierProvider);
    await container.read(walletNotifierProvider.notifier).loadWalletData();
    return _App._(storage, container);
  }

  Future<CsvImportPlan> plan(String csv) {
    return CsvImportService(storage.open()).planImport(
      csv,
      walletNames: [
        for (final card in container.read(walletNotifierProvider).cards)
          card.bankName,
      ],
      now: _now,
    );
  }

  /// Checks [csv] and imports it, as Settings does.
  Future<CsvImportPlan> import(String csv) async {
    final checked = await plan(csv);
    await container
        .read(walletNotifierProvider.notifier)
        .importTransactions(checked.transactions);
    return checked;
  }

  Future<void> expectRejected(String csv, Matcher message) async {
    await expectLater(
      import(csv),
      throwsA(
        isA<CsvImportException>().having((e) => e.message, 'message', message),
      ),
    );
  }

  Map<String, double> get balances => {
        for (final card in container.read(walletNotifierProvider).cards)
          card.bankName: card.balance,
      };

  FinancialSummaryModel get summary =>
      container.read(homeNotifierProvider).summary!;

  Map<String, double> get spendingByTitle {
    final totals = <String, double>{};
    for (final tx in container.read(homeNotifierProvider).transactions) {
      if (tx.resolvedKind != TransactionKind.expense) continue;
      totals[tx.title] = (totals[tx.title] ?? 0) + tx.amount;
    }
    return totals;
  }

  /// Balances as a fresh launch would show them, read from disk.
  Future<Map<String, double>> storedBalances() async {
    final prefs = SqlitePrefs(storage.open());
    await prefs.init();
    final cards = await prefs.readJsonList(
      'wallet_cards_list',
      WalletCardModel.fromJson,
    );
    final transactions =
        await MoneyTrackerRepository(storage.open()).getTransactions();
    return {
      for (final card in withDerivedBalances(cards, transactions))
        card.bankName: card.balance,
    };
  }

  Future<String?> storedWalletsJson() async {
    final prefs = SqlitePrefs(storage.open());
    await prefs.init();
    return prefs.getString('wallet_cards_list');
  }

  Future<Map<Object?, Map<String, Object?>>> rowsById() async => {
        for (final row in await storage.transactionRows()) row['id']: row,
      };
}

TransactionModel _tx(
  String id,
  String title,
  double amount,
  String wallet, {
  bool income = false,
  String kind = 'expense',
  String? from,
  String? to,
  String currency = 'INR',
}) =>
    TransactionModel(
      id: id,
      title: title,
      date: '10-09-2026',
      amount: amount,
      currency: currency,
      isIncome: income,
      bankName: wallet,
      timestamp: '26-09-10   09 : 00',
      kind: kind,
      transferFrom: from,
      transferTo: to,
    );
