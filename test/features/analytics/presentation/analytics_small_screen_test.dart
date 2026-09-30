import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/analytics/presentation/analytics/analytics_mobile.dart';
import 'package:zenio/features/analytics/presentation/widgets/top_spent_card.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../../helpers/test_storage.dart';

void main() {
  testWidgets('on a small phone with large text, top spending is reached',
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
    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
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
      for (final (i, title) in ['Food', 'Travel', 'Bills'].indexed) {
        await seedTransaction(
          db,
          TransactionModel(
            id: 't$i',
            title: title,
            date: today,
            amount: 100.0 * (i + 1),
            currency: 'INR',
            isIncome: false,
            bankName: 'HDFC',
            kind: 'expense',
          ),
        );
      }
    });
    final container = storage.container();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(sqlitePrefsProvider.future);
      await container.read(walletNotifierProvider.notifier).loadWalletData();
      await container
          .read(homeNotifierProvider.notifier)
          .loadMoneyTrackerData();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AnalyticsScreenMobile()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    // The chart and the list scroll together here, so a drag on the chart
    // brings the categories into view.
    await tester.drag(find.text('Top spending'), const Offset(0, -400));
    await tester.pump();

    expect(find.byType(TopSpentCard).hitTestable(), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
