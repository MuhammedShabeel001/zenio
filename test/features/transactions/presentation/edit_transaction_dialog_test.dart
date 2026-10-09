import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/implementations/money_tracker/money_tracker_repository.dart';
import 'package:zenio/features/home/domain/repositories/interfaces/money_tracker/i_money_tracker_repository.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/settings/domain/models/settings_model.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/presentation/widgets/edit_transaction_dialog.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../../helpers/test_storage.dart';

/// The one transaction being edited, kept in memory; records the update.
class _OneTransaction implements IMoneyTrackerRepository {
  _OneTransaction(this.transaction);

  TransactionModel transaction;
  TransactionModel? updated;

  @override
  Future<List<TransactionModel>> getTransactions() async => [transaction];

  @override
  Future<void> updateTransaction(TransactionModel transaction) async =>
      updated = this.transaction = transaction;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

TransactionModel _model(TransactionDetailModel tx) => TransactionModel(
      id: tx.id,
      title: tx.title,
      date: tx.date,
      amount: tx.amount,
      currency: tx.currency,
      isIncome: tx.isIncome,
      note: tx.note,
      bankName: tx.bankName,
      timestamp: tx.timestamp,
      kind: tx.kind,
      transferFrom: tx.transferFrom,
      transferTo: tx.transferTo,
    );

/// Opens the Edit dialog for [transaction] with [wallets] (name → balance).
Future<_OneTransaction> _openEdit(
  WidgetTester tester,
  TransactionDetailModel transaction, {
  Map<String, double> wallets = const {'HDFC': 1000},
}) async {
  // Tall and wide enough for the whole dialog in the wide test font.
  tester.view.physicalSize = const Size(1800, 4500);
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
        defaultWallet: wallets.keys.first,
        isBiometricEnabled: false,
        supportEmail: 'support@zenio.app',
        appVersion: '2.0.0',
      ).toJson(),
    ),
  });
  PackageInfo.setMockInitialValues(
    appName: 'Zenio',
    packageName: 'com.auren.zenio',
    version: '2.0.0',
    buildNumber: '2',
    buildSignature: '',
  );
  final storage = TestStorage.create();
  await tester.runAsync(
    () => storage.putKeyValue(
      'wallet_cards_list',
      jsonEncode([
        for (final entry in wallets.entries)
          jsonEncode(
            WalletCardModel(
              id: entry.key,
              bankName: entry.key,
              cardNumber: '',
              cardType: 'DEBIT CARD',
              gradientStartHex: '0xFF000000',
              gradientEndHex: '0xFF111111',
              openingBalance: entry.value,
            ).toJson(),
          ),
      ]),
    ),
  );
  final repository = _OneTransaction(_model(transaction));
  final container = storage.container(
    overrides: [
      moneyTrackerRepositoryRepoProvider.overrideWith((ref) => repository),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(() async {
    await container.read(sqlitePrefsProvider.future);
    await container
        .read(settingsNotifierProvider.notifier)
        .isVaultLockEnabled();
    container.read(categoriesNotifierProvider);
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
              onPressed: () => EditTransactionDialog.show(
                context,
                transaction: transaction,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return repository;
}

/// Saves in real time: the notifiers were loaded in real time.
Future<void> _save(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.text('Save changes'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pump();
}

void main() {
  testWidgets('editing shows the note, wallet, date and time', (tester) async {
    await _openEdit(
      tester,
      const TransactionDetailModel(
        id: 't1',
        title: 'Food',
        date: '15-09-2026',
        amount: 420,
        isIncome: false,
        currency: 'INR',
        note: 'Lunch with the team',
        bankName: 'HDFC',
        timestamp: '26-09-15   13 : 05',
        kind: 'expense',
      ),
    );

    expect(find.text('Lunch with the team'), findsOneWidget);
    expect(find.text('HDFC'), findsWidgets);
    expect(find.text('15 Sep 2026'), findsOneWidget);
    // The time the list showed before, kept when the date changes.
    expect(find.text('13:05'), findsOneWidget);
  });

  testWidgets('a transfer between wallets named with "->" shows them whole',
      (tester) async {
    const from = 'Personal -> Savings -> Emergency';
    const to = 'Savings -> Emergency';
    final repository = await _openEdit(
      tester,
      const TransactionDetailModel(
        id: 't1',
        title: 'Transfer to $to',
        date: '15-09-2026',
        amount: 50,
        isIncome: false,
        currency: 'INR',
        bankName: '$from -> $to',
        kind: 'transfer',
        transferFrom: from,
        transferTo: to,
      ),
      wallets: {from: 500, to: 100, 'Personal': 5},
    );

    expect(find.text(from), findsOneWidget);
    expect(find.text(to), findsOneWidget);

    await _save(tester);

    expect(repository.updated!.transferFrom, from);
    expect(repository.updated!.transferTo, to);
    expect(repository.updated!.bankName, '$from -> $to');
  });

  testWidgets(
      'saving an expense on a wallet named with "->" keeps it on that wallet',
      (tester) async {
    // Before, the dialog read "HDFC->Salary" as a transfer from "HDFC", and
    // saving without a change moved the expense to that other wallet.
    final repository = await _openEdit(
      tester,
      const TransactionDetailModel(
        id: 'e1',
        title: 'Food',
        date: '15-09-2026',
        amount: 20,
        isIncome: false,
        currency: 'INR',
        bankName: 'HDFC->Salary',
        kind: 'expense',
      ),
      wallets: {'HDFC->Salary': 500, 'HDFC': 1000},
    );

    await _save(tester);

    expect(repository.updated!.bankName, 'HDFC->Salary');
    expect(repository.updated!.transferFrom, isNull);
    expect(repository.updated!.transferTo, isNull);
  });

  testWidgets('Edit reads like Add: same order, labels and button',
      (tester) async {
    await _openEdit(
      tester,
      const TransactionDetailModel(
        id: 'i1',
        title: 'Salary',
        date: '15-09-2026',
        amount: 5000,
        isIncome: true,
        currency: 'INR',
        bankName: 'HDFC',
        kind: 'income',
      ),
    );

    // Amount, date, wallet, category, note: the order of Add transaction.
    final date = tester.getTopLeft(find.text('15 Sep 2026')).dy;
    final wallet = tester.getTopLeft(find.text('HDFC').first).dy;
    final category = tester.getTopLeft(find.text('Category (optional)')).dy;
    final note = tester.getTopLeft(find.text('Add a note...')).dy;
    expect(date, lessThan(wallet));
    expect(wallet, lessThan(category));
    expect(category, lessThan(note));
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('Edit income'), findsOneWidget);
  });
}
