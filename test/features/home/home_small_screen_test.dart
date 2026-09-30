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

void main() {
  testWidgets('on a small phone with large text, the transactions are reached',
      (tester) async {
    // A small phone's height (568pt) with 1.3x text. Wider than 320pt only
    // because the test font draws every letter a full square wide.
    tester.view.physicalSize = const Size(1400, 1136);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Zenio',
      packageName: 'com.aurea.zenio',
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
              id: 'h',
              bankName: 'HDFC',
              cardNumber: '',
              cardType: 'BANK',
              gradientStartHex: '0xFF000000',
              gradientEndHex: '0xFF111111',
              openingBalance: 5000,
            ).toJson(),
          ),
        ]),
      );
      final db = storage.open();
      for (var i = 0; i < 3; i++) {
        await seedTransaction(
          db,
          TransactionModel(
            id: 't$i',
            title: 'Row $i',
            date: '2${i + 1}-09-2026',
            amount: 10,
            currency: 'INR',
            isIncome: false,
            bankName: 'HDFC',
            timestamp: '26-09-2${i + 1}   09 : 00',
            kind: 'expense',
          ),
        );
      }
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
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    // The quick actions and header scroll with the list here, so a drag on
    // them brings the transactions into view.
    await tester.drag(find.text('Transactions'), const Offset(0, -400));
    await tester.pump();

    // Even the last transaction can be scrolled into view.
    expect(find.text('Row 0').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
