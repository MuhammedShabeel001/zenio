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
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/presentation/widgets/adjust_balance_bottom_sheet.dart';
import 'package:zenio/features/wallet/presentation/widgets/edit_wallet_dialog.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../../helpers/test_storage.dart';

class _Memory implements IMoneyTrackerRepository {
  final List<TransactionModel> saved = [];

  @override
  Future<List<TransactionModel>> getTransactions() async => List.of(saved);

  @override
  Future<void> insertTransaction(TransactionModel transaction) async =>
      saved.add(transaction);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _Memory transactions;
  late ProviderContainer container;

  Future<void> open(
    WidgetTester tester,
    void Function(BuildContext) show,
  ) async {
    tester.view.physicalSize = const Size(1800, 4500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Zenio',
      packageName: 'com.auren.zenio',
      version: '2.0.0',
      buildNumber: '2',
      buildSignature: '',
    );
    transactions = _Memory();
    final storage = TestStorage.create();
    await tester.runAsync(
      () => storage.putKeyValue(
        'wallet_cards_list',
        jsonEncode([
          jsonEncode(
            const WalletCardModel(
              id: 'h',
              bankName: 'HDFC',
              cardNumber: '',
              cardType: 'BANK',
              gradientStartHex: '0xFF000000',
              gradientEndHex: '0xFF111111',
              balance: 1000,
              openingBalance: 1000,
            ).toJson(),
          ),
        ]),
      ),
    );
    container = storage.container(
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
      container.read(homeNotifierProvider);
      await container.read(walletNotifierProvider.notifier).loadWalletData();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => show(context),
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
  }

  /// Taps [text], whose save writes to a real database, and waits in real
  /// time until [until] shows (up to five seconds on a busy machine).
  Future<void> tapInRealTime(
    WidgetTester tester,
    String text, {
    required Finder until,
  }) async {
    await tester.runAsync(() => tester.tap(find.text(text)));
    for (var i = 0; i < 50 && until.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));
  }

  ElevatedButton button(WidgetTester tester, String label) =>
      tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(ElevatedButton),
        ),
      );

  testWidgets('Adjust says where the balance ends up before saving',
      (tester) async {
    await open(tester, (context) => AdjustBalanceBottomSheet.show(context, 0));

    // Neutral words: a correction, not income.
    expect(find.text('Increase'), findsOneWidget);
    expect(find.text('Decrease'), findsOneWidget);
    expect(find.text('Set to'), findsOneWidget);
    expect(button(tester, 'Increase balance').onPressed, isNull);

    await tester.enterText(find.byType(TextField), '200');
    await tester.pump();
    expect(find.text('New balance: ₹1,200.00'), findsOneWidget);
    expect(button(tester, 'Increase balance').onPressed, isNotNull);

    final confirmation = find.text('HDFC balance is now ₹1,200.00');
    await tapInRealTime(tester, 'Increase balance', until: confirmation);

    expect(confirmation, findsOneWidget);
    final adjustment = transactions.saved.single;
    expect(adjustment.kind, 'adjustment');
    expect(adjustment.amount, 200);
    expect(adjustment.isIncome, isTrue);
  });

  testWidgets('Adjust cannot save a balance that stays the same',
      (tester) async {
    await open(tester, (context) => AdjustBalanceBottomSheet.show(context, 0));

    await tester.tap(find.text('Set to'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '1000');
    await tester.pump();

    expect(find.textContaining('New balance'), findsNothing);
    expect(button(tester, 'Set balance').onPressed, isNull);
  });

  testWidgets('Editing a wallet says what a new balance records',
      (tester) async {
    await open(
      tester,
      (context) => EditWalletDialog.show(
        context,
        card: container.read(walletNotifierProvider).cards.single,
        cardIndex: 0,
      ),
    );
    expect(find.text('Current balance'), findsOneWidget);
    expect(find.textContaining('records a balance adjustment'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '1,500');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.textContaining('records a balance adjustment of +₹500.00'),
      findsOneWidget,
    );

    final confirmation = find.text('Wallet saved · balance is now ₹1,500.00');
    await tapInRealTime(tester, 'Save changes', until: confirmation);

    expect(confirmation, findsOneWidget);
    expect(transactions.saved.single.amount, 500);
  });
}
