import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/home/home.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/shared/providers/clock_provider/clock_provider.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../helpers/test_storage.dart';

TransactionModel _tx(
  String id,
  String date,
  double amount, {
  bool income = false,
}) =>
    TransactionModel(
      id: id,
      title: income ? 'Salary' : 'Food',
      date: date,
      amount: amount,
      currency: 'INR',
      isIncome: income,
      bankName: 'HDFC',
      timestamp: '${date.substring(8)}-${date.substring(3, 5)}-'
          '${date.substring(0, 2)}   09 : 00',
      kind: income ? 'income' : 'expense',
    );

/// August, September and October 2026.
final _history = [
  _tx('aug-in', '10-08-2026', 800, income: true),
  _tx('aug-out', '11-08-2026', 200),
  _tx('sep-in', '10-09-2026', 1000, income: true),
  _tx('sep-out', '11-09-2026', 300),
  _tx('oct-in', '01-10-2026', 5000, income: true),
  _tx('oct-out', '01-10-2026', 700),
];

/// The transactions in memory; counts every write.
class _Transactions implements IMoneyTrackerRepository {
  int writes = 0;

  @override
  Future<List<TransactionModel>> getTransactions() async => List.of(_history);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    writes++;
    throw UnimplementedError();
  }
}

void main() {
  group('Home notifier', () {
    late DateTime now;
    late _Transactions repository;
    late ProviderContainer container;

    Future<HomeNotifier> load() async {
      repository = _Transactions();
      container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => now),
          moneyTrackerRepositoryRepoProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(homeNotifierProvider.notifier);
      await notifier.loadMoneyTrackerData();
      return notifier;
    }

    test('moves "This month" from September 30 to October 1', () async {
      now = DateTime(2026, 9, 30, 23, 59);
      final notifier = await load();
      var summary = container.read(homeNotifierProvider).summary!;
      expect((summary.income, summary.expense), (1000, 300));
      // Compared with August.
      expect(summary.incomeChangePercentage, 25);
      expect(summary.expenseChangePercentage, 50);

      now = DateTime(2026, 10, 1, 0, 1);
      expect(notifier.refreshForCurrentMonth(), isTrue);

      summary = container.read(homeNotifierProvider).summary!;
      expect((summary.income, summary.expense), (5000, 700));
      // Now compared with September.
      expect(summary.incomeChangePercentage, 400);
      expect(summary.expenseChangePercentage, closeTo(133.33, 0.01));
    });

    test('starting in October uses October', () async {
      now = DateTime(2026, 10, 1, 8);
      await load();

      final summary = container.read(homeNotifierProvider).summary!;
      expect((summary.income, summary.expense), (5000, 700));
      expect(summary.incomeChangePercentage, 400);
    });

    test('within the same month nothing is worked out again', () async {
      now = DateTime(2026, 9, 2);
      final notifier = await load();
      final before = container.read(homeNotifierProvider).summary;

      now = DateTime(2026, 9, 30, 23, 59);
      expect(notifier.refreshForCurrentMonth(), isFalse);
      expect(container.read(homeNotifierProvider).summary, same(before));
    });

    test('the transactions themselves are not touched', () async {
      now = DateTime(2026, 9, 30, 23, 59);
      final notifier = await load();
      final before = container.read(homeNotifierProvider).transactions;

      now = DateTime(2026, 10, 1, 0, 1);
      notifier.refreshForCurrentMonth();

      final after = container.read(homeNotifierProvider).transactions;
      expect(after, before);
      expect(after.map((t) => t.amount), before.map((t) => t.amount));
      expect(repository.writes, 0);
    });
  });

  group('Home screen', () {
    late DateTime now;

    Future<void> openHome(WidgetTester tester) async {
      // Wide and tall enough for Home in the wide test font.
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
          jsonEncode([
            jsonEncode(
              const WalletCardModel(
                id: 'HDFC',
                bankName: 'HDFC',
                cardNumber: '',
                cardType: 'BANK',
                gradientStartHex: '0xFF000000',
                gradientEndHex: '0xFF111111',
                openingBalance: 0,
              ).toJson(),
            ),
          ]),
        );
        final db = storage.open();
        for (final tx in _history) {
          await seedTransaction(db, tx);
        }
      });
      final container = storage.container(
        overrides: [clockProvider.overrideWithValue(() => now)],
      );
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        await container.read(sqlitePrefsProvider.future);
        await container
            .read(homeNotifierProvider.notifier)
            .loadMoneyTrackerData();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('after coming back on October 1, Home shows October',
        (tester) async {
      now = DateTime(2026, 9, 30, 22);
      await openHome(tester);
      expect(find.text('₹1,000.00'), findsOneWidget);
      expect(find.text('+25% vs last month'), findsOneWidget);

      // Zenio goes to the background overnight and comes back, through the
      // states the system reports.
      void moveTo(List<AppLifecycleState> states) {
        for (final state in states) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
      }

      moveTo([
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]);
      now = DateTime(2026, 10, 1, 7, 30);
      moveTo([
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
      await tester.pump();

      expect(find.text('₹5,000.00'), findsOneWidget);
      expect(find.text('₹700.00'), findsOneWidget);
      expect(find.text('+400% vs last month'), findsOneWidget);
      expect(find.text('₹1,000.00'), findsNothing);
    });

    testWidgets('left open across midnight, Home moves to the new month',
        (tester) async {
      now = DateTime(2026, 9, 30, 23, 59, 58);
      await openHome(tester);
      expect(find.text('₹1,000.00'), findsOneWidget);

      now = DateTime(2026, 10, 1, 0, 0, 5);
      await tester.pump(const Duration(seconds: 4));

      expect(find.text('₹5,000.00'), findsOneWidget);
    });
  });
}
