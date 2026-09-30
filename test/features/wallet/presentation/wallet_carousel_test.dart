import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/presentation/wallet/wallet_mobile.dart';
import 'package:zenio/features/wallet/presentation/widgets/wallet_card_widget.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../../helpers/test_storage.dart';

WalletCardModel _card(String id, String name) => WalletCardModel(
      id: id,
      bankName: name,
      cardNumber: '1234',
      cardType: 'Debit Card',
      gradientStartHex: '0xFF000000',
      gradientEndHex: '0xFF111111',
      balance: 100,
    );

void main() {
  late ProviderContainer container;

  Future<void> showWallets(WidgetTester tester) async {
    // Wide enough that the test font does not wrap the card number.
    tester.view.physicalSize = const Size(1600, 2600);
    tester.view.devicePixelRatio = 2;
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
      packageName: 'com.aurea.zenio',
      version: '2.0.0',
      buildNumber: '2',
      buildSignature: '',
    );
    final storage = TestStorage.create();
    await tester.runAsync(
      () => storage.putKeyValue(
        'wallet_cards_list',
        jsonEncode([
          for (final c in [
            _card('a', 'HDFC'),
            _card('b', 'SBI'),
            _card('c', 'Cash'),
          ])
            jsonEncode(c.toJson()),
        ]),
      ),
    );
    container = storage.container();
    await tester.runAsync(() async {
      await container.read(sqlitePrefsProvider.future);
      container.read(homeNotifierProvider);
      await container.read(walletNotifierProvider.notifier).loadWalletData();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: WalletScreenMobile()),
      ),
    );
    await tester.pump();
  }

  /// Lets database work finish between frames until [done], giving up after
  /// a few seconds.
  Future<void> settle(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 150 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('freezing the card on screen shows that card frozen',
      (tester) async {
    await showWallets(tester);

    await tester.tap(find.text('Freeze'));
    await settle(
      tester,
      () => container.read(walletNotifierProvider).cards.any((c) => c.isFrozen),
    );

    final frozen = tester
        .widgetList<WalletCardWidget>(find.byType(WalletCardWidget))
        .where((w) => w.isFrozen)
        .map((w) => w.card.id);
    final state = container.read(walletNotifierProvider);
    final onScreen = state.cards[state.activeCardIndex % state.cards.length];
    expect(onScreen.isFrozen, isTrue);
    expect(frozen, [onScreen.id]);

    // Says what freezing does, and can be undone.
    expect(find.text('Unfreeze'), findsOneWidget);
    expect(
      find.text('${onScreen.bankName} frozen · not counted in Total balance'),
      findsOneWidget,
    );
    await tester.tap(find.text('Undo'));
    await settle(
      tester,
      () => container
          .read(walletNotifierProvider)
          .cards
          .every((c) => !c.isFrozen),
    );
    expect(find.text('Freeze'), findsOneWidget);
  });

  testWidgets('a new wallet is brought into view', (tester) async {
    await showWallets(tester);

    await tester.runAsync(
      () => container
          .read(walletNotifierProvider.notifier)
          .addCard(_card('d', 'Savings'), 0),
    );
    await tester.pumpAndSettle();

    final state = container.read(walletNotifierProvider);
    expect(state.cards[state.activeCardIndex % state.cards.length].id, 'd');
  });
}
