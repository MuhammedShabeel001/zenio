import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/implementations/money_tracker/money_tracker_repository.dart';
import 'package:zenio/features/home/domain/repositories/interfaces/money_tracker/i_money_tracker_repository.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/settings/domain/models/settings_model.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';
import 'package:zenio/shared/widgets/add_transaction_bottom_sheet.dart';

import '../../helpers/test_storage.dart';

/// Transactions kept in memory, so saving completes within the test.
class _MemoryTransactions implements IMoneyTrackerRepository {
  final List<TransactionModel> saved = [];

  @override
  Future<List<TransactionModel>> getTransactions() async => List.of(saved);

  @override
  Future<void> insertTransaction(TransactionModel transaction) async =>
      saved.add(transaction);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

WalletCardModel _wallet(String id, String name, String type) =>
    WalletCardModel(
      id: id,
      bankName: name,
      cardNumber: '',
      cardType: type,
      gradientStartHex: '0xFF000000',
      gradientEndHex: '0xFF111111',
      openingBalance: 0,
    );

void main() {
  late _MemoryTransactions transactions;

  Future<void> openSheet(
    WidgetTester tester, {
    required String defaultWallet,
  }) async {
    // Tall enough for the whole sheet in the test font, which is wider
    // than the real one.
    tester.view.physicalSize = const Size(1170, 4500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    SharedPreferences.setMockInitialValues({
      'app_user_settings': jsonEncode(
        SettingsModel(
          primaryCurrency: 'INR',
          defaultWallet: defaultWallet,
          isBiometricEnabled: false,
          supportEmail: 'support@zenio.app',
          appVersion: '2.0.0',
        ).toJson(),
      ),
    });
    PackageInfo.setMockInitialValues(
      appName: 'Zenio',
      packageName: 'com.aurea.zenio',
      version: '2.0.0',
      buildNumber: '2',
      buildSignature: '',
    );
    transactions = _MemoryTransactions();
    final storage = TestStorage.create();
    await tester.runAsync(
      () => storage.putKeyValue(
        'wallet_cards_list',
        jsonEncode([
          for (final w in [
            _wallet('c', 'Amex', 'CREDIT CARD'),
            _wallet('d', 'HDFC', 'DEBIT CARD'),
          ])
            jsonEncode(w.toJson()),
        ]),
      ),
    );
    final container = storage.container(
      overrides: [
        moneyTrackerRepositoryRepoProvider.overrideWith((ref) => transactions),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(sqlitePrefsProvider.future);
      await container
          .read(settingsNotifierProvider.notifier)
          .isVaultLockEnabled();
      container
        ..read(homeNotifierProvider)
        ..read(categoriesNotifierProvider);
      await container.read(walletNotifierProvider.notifier).loadWalletData();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AddTransactionBottomSheet.show(context),
                child: const Text('Add'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Add'));
    // Let the sheet slide in and the amount field take focus.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Saves in real time: the notifiers were loaded in real time, and their
  /// futures resume there.
  Future<void> save(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(find.text('Save transaction'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> enterAmount(WidgetTester tester, String amount) async {
    await tester.enterText(find.byType(TextField).first, amount);
    await tester.pump();
  }

  testWidgets('a credit card can go below zero, and says where it lands',
      (tester) async {
    await openSheet(tester, defaultWallet: 'Amex');
    await enterAmount(tester, '500');

    expect(
      find.text('Balance after transaction: −₹500.00'),
      findsOneWidget,
    );
    expect(find.text('Insufficient Wallet Balance'), findsNothing);

    await save(tester);

    expect(transactions.saved.single.bankName, 'Amex');
    expect(transactions.saved.single.amount, 500);
    expect(find.textContaining('Expense added'), findsOneWidget);
  });

  testWidgets('other wallets still need the money', (tester) async {
    await openSheet(tester, defaultWallet: 'HDFC');
    await enterAmount(tester, '500');

    expect(find.text('Insufficient Wallet Balance'), findsOneWidget);
    expect(find.textContaining('Balance after transaction'), findsNothing);
  });

  testWidgets('income without a category is saved as Income, not Food',
      (tester) async {
    await openSheet(tester, defaultWallet: 'HDFC');
    await tester.tap(find.text('Income'));
    await tester.pump();
    await enterAmount(tester, '1200');

    expect(find.text('Category (optional)'), findsOneWidget);
    await save(tester);

    final saved = transactions.saved.single;
    expect(saved.title, 'Income');
    expect(saved.isIncome, isTrue);
    expect(find.text('Income added · Income · ₹1,200'), findsOneWidget);
  });

  testWidgets('a transfer names its From and To wallets', (tester) async {
    await openSheet(tester, defaultWallet: 'HDFC');
    await tester.tap(find.text('Transfer'));
    await tester.pump();

    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.bySemanticsLabel('Swap From and To wallets'), findsOneWidget);
  });
}
