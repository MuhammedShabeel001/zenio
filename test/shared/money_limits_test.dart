import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/analytics/controller/analytics/analytics_notifier.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/features/debts/domain/repositories/implementations/debts_repository.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/implementations/money_tracker/money_tracker_repository.dart';
import 'package:zenio/features/home/presentation/home/home.dart';
import 'package:zenio/features/split/domain/models/split_calculation_model.dart';
import 'package:zenio/features/split/domain/repositories/implementations/split_repository.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/domain/repositories/implementations/subscriptions_repository.dart';
import 'package:zenio/features/transactions/controller/transactions/transactions_notifier.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/repositories/implementations/wallet_repository.dart';
import 'package:zenio/shared/providers/clock_provider/clock_provider.dart';
import 'package:zenio/shared/services/csv_export_service.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';
import 'package:zenio/shared/utils/formatters.dart';
import 'package:zenio/shared/utils/money_limits.dart';

import '../helpers/test_storage.dart';

const _invalid = [double.infinity, double.negativeInfinity, double.nan];

const _brokenWallet =
    '{"id":"x","bank_name":"Broken","card_number":"","card_type":"BANK",'
    '"gradient_start":"","gradient_end":"","balance":1e400}';

const _brokenDebt =
    '{"id":"d","personName":"Anu","date":"10-09-2026","amount":1e400,'
    '"currency":"INR","isOwed":true,"iconName":""}';

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

Map<String, dynamic> _row(String id, Object amount) => {
      'id': id,
      'title': 'Food',
      'date': '10-09-2026',
      'amount': amount,
      'currency': 'INR',
      'is_income': 0,
      'bank_name': 'HDFC',
      'timestamp': '26-09-10   09 : 00',
      'kind': 'expense',
    };

void main() {
  group('amounts', () {
    test('the largest valid amount is accepted', () {
      expect(isStorableAmount(maxMoneyAmount), isTrue);
      expect(isStorableAmount(-maxMoneyAmount), isTrue);
      expect(
        AppNumberFormat.tryParseAmount('999,999,999,999.99'),
        maxMoneyAmount,
      );
    });

    test('larger, overflowing and non-numbers are not amounts', () {
      expect(isStorableAmount(1e12), isFalse);
      for (final value in _invalid) {
        expect(isStorableAmount(value), isFalse, reason: '$value');
        expect(
          () => checkStorableAmount(value, 'amount'),
          throwsA(isA<InvalidAmountException>()),
        );
      }
      for (final text in [
        '9999999999999', // 13 digits
        '9' * 400, // parses to Infinity
        'Infinity',
        'NaN',
        'abc',
        '-',
        '',
      ]) {
        expect(AppNumberFormat.tryParseAmount(text), isNull, reason: text);
        // Callers that treat "no amount" as 0 never get NaN or Infinity.
        expect(AppNumberFormat.parseAmount(text), 0, reason: text);
      }
    });

    test('amount fields refuse a 13th digit, typed or pasted', () {
      final formatter = ThousandsSeparatorInputFormatter();
      const old = TextEditingValue(
        text: '999,999,999,999',
        selection: TextSelection.collapsed(offset: 15),
      );

      final typed = formatter.formatEditUpdate(
        old,
        const TextEditingValue(
          text: '999,999,999,9999',
          selection: TextSelection.collapsed(offset: 16),
        ),
      );
      final pasted = formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: '9' * 400,
          selection: const TextSelection.collapsed(offset: 400),
        ),
      );

      expect(typed.text, '999,999,999,999');
      expect(pasted.text, '');
      expect(
        ThousandsSeparatorInputFormatter(allowNegative: true)
            .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(
                text: '-9999999999999',
                selection: TextSelection.collapsed(offset: 14),
              ),
            )
            .text,
        isNot(contains('9999999999999')),
      );
    });
  });

  group('storage refuses invalid amounts', () {
    test('transactions', () async {
      final db = TestStorage.create().open();

      for (final value in _invalid) {
        await expectLater(
          db.insertTransactionMap(_row('x', value)),
          throwsA(isA<InvalidAmountException>()),
        );
      }
      await expectLater(
        db.updateTransactionMap(_row('x', double.infinity)),
        throwsA(isA<InvalidAmountException>()),
      );
      // One bad row stops the whole batch.
      await expectLater(
        db.saveTransactionMaps([_row('a', 10.0), _row('b', double.nan)]),
        throwsA(isA<InvalidAmountException>()),
      );
      await db.insertTransactionMap(_row('max', maxMoneyAmount));

      expect(
        (await db.getTransactionsMap()).map((r) => r['id']),
        ['max'],
      );
    });

    test('wallets, debts, subscriptions and the split', () async {
      final storage = TestStorage.create();
      final prefs = SqlitePrefs(storage.open());
      await prefs.init();

      await expectLater(
        WalletRepository(prefs).saveCards([_wallet('HDFC', double.infinity)]),
        throwsA(isA<InvalidAmountException>()),
      );
      await expectLater(
        DebtsRepository(prefs).saveDebts([
          const DebtModel(
            id: 'd',
            personName: 'Anu',
            date: '10-09-2026',
            amount: double.infinity,
            currency: 'INR',
            isOwed: true,
            iconName: '',
          ),
        ]),
        throwsA(isA<InvalidAmountException>()),
      );
      await expectLater(
        SubscriptionsRepository(prefs).saveSubscriptions([
          SubscriptionModel(
            id: 's',
            title: 'Netflix',
            category: 'Streaming',
            amount: double.nan,
            currency: 'INR',
            nextBillingDate: DateTime(2026, 10),
            billingCycle: 'Monthly',
            iconName: '',
          ),
        ]),
        throwsA(isA<InvalidAmountException>()),
      );
      await expectLater(
        SplitRepository(prefs).saveSplit(
          const SplitCalculationModel(
            billAmount: double.negativeInfinity,
            peopleCount: 2,
            returnersCount: 1,
            mode: SplitMode.equal,
          ),
        ),
        throwsA(isA<InvalidAmountException>()),
      );
      expect(prefs.getString('wallet_cards_list'), isNull);
    });
  });

  group('with the app', () {
    late TestStorage storage;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'Zenio',
        packageName: 'com.auren.zenio',
        version: '2.0.0',
        buildNumber: '2',
        buildSignature: '',
      );
      storage = TestStorage.create();
    });

    Future<void> launch() async {
      container = storage.container(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime(2026, 9, 30, 12)),
        ],
      );
      await container.read(sqlitePrefsProvider.future);
      container.read(walletNotifierProvider);
      await container.read(walletNotifierProvider.notifier).loadWalletData();
    }

    test('a wallet or balance change with an invalid amount changes nothing',
        () async {
      await storage.putKeyValue(
        'wallet_cards_list',
        jsonEncode([jsonEncode(_wallet('HDFC', 500).toJson())]),
      );
      await launch();
      final notifier = container.read(walletNotifierProvider.notifier);

      for (final value in [..._invalid, 1e13]) {
        await expectLater(
          notifier.addCard(_wallet('Cash', 0), value),
          throwsA(isA<InvalidAmountException>()),
        );
        await expectLater(
          notifier.adjustBalance('HDFC', value),
          throwsA(isA<InvalidAmountException>()),
        );
      }
      await notifier.idle();

      final cards = container.read(walletNotifierProvider).cards;
      expect(cards.map((c) => c.bankName), ['HDFC']);
      expect(cards.single.balance, 500);
      expect(container.read(homeNotifierProvider).transactions, isEmpty);
    });

    test('stored invalid amounts are set aside, not shown, not changed',
        () async {
      await storage.putKeyValue(
        'wallet_cards_list',
        jsonEncode([
          jsonEncode(_wallet('HDFC', 1000).toJson()),
          // A number JSON can hold but Zenio cannot use.
          _brokenWallet,
        ]),
      );
      await storage.putKeyValue(
        'debts_list_key_v2',
        jsonEncode([_brokenDebt]),
      );
      final db = storage.open();
      await seedTransaction(
        db,
        const TransactionModel(
          id: 'ok',
          title: 'Food',
          date: '10-09-2026',
          amount: 120,
          currency: 'INR',
          isIncome: false,
          bankName: 'HDFC',
          kind: 'expense',
        ),
      );
      // Written past the checks, as an older version could have.
      await (await db.database)
          .insert('transactions', _row('bad', double.infinity));

      await launch();

      final home = container.read(homeNotifierProvider);
      expect(home.transactions.map((t) => t.id), ['ok']);
      expect(home.summary!.expense, 120);
      expect(home.summary!.expense.isFinite, isTrue);
      final cards = container.read(walletNotifierProvider).cards;
      expect(cards.map((c) => c.bankName), ['HDFC']);
      expect(cards.single.balance, 880);
      expect(container.read(walletNotifierProvider).cardBalance, 880);
      expect(
        container.read(transactionsNotifierProvider).totalBalance.isFinite,
        isTrue,
      );
      expect(
        container.read(analyticsNotifierProvider).totalBalance.isFinite,
        isTrue,
      );
      expect(
        await DebtsRepository(container.read(sqlitePrefsProvider).value!)
            .getDebts(),
        isEmpty,
      );

      // Nothing was changed or lost: the bad row and entries are still there.
      final rows = await storage.transactionRows();
      expect(
        rows.firstWhere((r) => r['id'] == 'bad')['amount'],
        double.infinity,
      );
      final prefs = SqlitePrefs(storage.open());
      await prefs.init();
      expect(
        prefs.getString('wallet_cards_list$unreadableKeySuffix'),
        contains('Broken'),
      );
      expect(
        prefs.getString('debts_list_key_v2$unreadableKeySuffix'),
        contains('Anu'),
      );

      // Export leaves it out rather than writing an impossible amount.
      final csv = CsvExportService.buildCsv(await db.getTransactionsMap());
      expect(csv, contains(',ok'));
      expect(csv, isNot(contains('bad')));
      expect(csv.toLowerCase(), isNot(contains('infinity')));
      expect(
        (await db.getTransactionsMap()).where(CsvExportService.isExportable),
        hasLength(1),
      );
    });
  });

  testWidgets('Home opens normally with a corrupted amount in storage',
      (tester) async {
    tester.view.physicalSize = const Size(1800, 4500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Zenio',
      packageName: 'com.auren.zenio',
      version: '2.0.0',
      buildNumber: '2',
      buildSignature: '',
    );
    final storage = TestStorage.create();
    await tester.runAsync(() async {
      await storage.putKeyValue(
        'wallet_cards_list',
        jsonEncode([jsonEncode(_wallet('HDFC', 1000).toJson())]),
      );
      final db = storage.open();
      await db.insertTransactionMap(_row('ok', 120.0));
      await (await db.database)
          .insert('transactions', _row('bad', double.infinity));
    });
    final container = storage.container(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 30, 12)),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(sqlitePrefsProvider.future);
      await container
          .read(homeNotifierProvider.notifier)
          .loadMoneyTrackerData();
      await container.read(walletNotifierProvider.notifier).loadWalletData();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    // The valid expense and the balance it leaves; nothing infinite.
    expect(find.text('₹120.00'), findsOneWidget);
    expect(find.textContaining('880'), findsWidgets);
  });

  test('a large amount older versions stored is still read and exported',
      () async {
    final db = TestStorage.create().open();
    // Beyond today's limit, but a real number: not corrupt.
    await (await db.database).insert('transactions', _row('big', 1e13));

    final loaded = await MoneyTrackerRepository(db).getTransactions();

    expect(loaded.single.amount, 1e13);
    expect(
      (await db.getTransactionsMap()).where(CsvExportService.isExportable),
      hasLength(1),
    );
  });

  test('a field holding too many digits can still be shortened', () {
    final formatter = ThousandsSeparatorInputFormatter();
    const old = TextEditingValue(
      text: '99,999,999,999,999',
      selection: TextSelection.collapsed(offset: 18),
    );

    final shortened = formatter.formatEditUpdate(
      old,
      const TextEditingValue(
        text: '99,999,999,999,99',
        selection: TextSelection.collapsed(offset: 17),
      ),
    );
    final longer = formatter.formatEditUpdate(
      old,
      const TextEditingValue(
        text: '99,999,999,999,9999',
        selection: TextSelection.collapsed(offset: 19),
      ),
    );

    expect(shortened.text, '9,999,999,999,999');
    expect(longer.text, old.text);
  });

  test('stored transactions keep loading when one amount is invalid', () async {
    final db = TestStorage.create().open();
    await db.insertTransactionMap(_row('ok', 25.0));
    final raw = await db.database;
    // SQLite itself stores NaN as NULL, which the amount column refuses.
    await expectLater(
      raw.insert('transactions', _row('nan', double.nan)),
      throwsA(anything),
    );
    await raw.insert('transactions', _row('inf', double.negativeInfinity));

    final loaded = await MoneyTrackerRepository(db).getTransactions();

    expect(loaded.map((t) => t.id), ['ok']);
  });
}
