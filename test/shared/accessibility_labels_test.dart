import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/feedback/presentation/widgets/feedback_bottom_sheet.dart';
import 'package:zenio/features/settings/presentation/widgets/settings_item_tile.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/presentation/widgets/subscription_card.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/transactions/presentation/widgets/manage_categories_bottom_sheet.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';
import 'package:zenio/features/vault/presentation/widgets/vault_note_item.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/presentation/widgets/add_wallet_bottom_sheet.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../helpers/test_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Zenio',
      packageName: 'com.aurea.zenio',
      version: '2.0.0',
      buildNumber: '2',
      buildSignature: '',
    );
  });

  /// A container with local storage open and [load] done in real time.
  Future<ProviderContainer> app(
    WidgetTester tester, {
    Future<void> Function(ProviderContainer container)? load,
  }) async {
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final container = TestStorage.create().container();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      await container.read(sqlitePrefsProvider.future);
      await load?.call(container);
    });
    return container;
  }

  Future<void> show(
    WidgetTester tester,
    ProviderContainer container,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(1800, 4500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pump();
  }

  testWidgets('the Vault Lock switch is named, with its state', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsItemTile(
            title: 'Vault Lock',
            icon: const Icon(Icons.fingerprint),
            isSwitch: true,
            onSwitchChanged: (_) {},
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('Vault Lock'));
    expect(node.getSemanticsData().flagsCollection.isToggled, Tristate.isFalse);
    semantics.dispose();
  });

  testWidgets('on a narrow row with large text, a picker goes under the title',
      (tester) async {
    tester.view.physicalSize = const Size(960, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsItemTile(
            title: 'Default wallet',
            icon: Icon(Icons.wallet),
            trailing: Text('HDFC Bank'),
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('HDFC Bank')).dy,
      greaterThan(tester.getBottomLeft(find.text('Default wallet')).dy),
    );
  });

  testWidgets('card designs are named and say which is chosen', (tester) async {
    final semantics = tester.ensureSemantics();
    final container = await app(
      tester,
      load: (c) => c.read(walletNotifierProvider.notifier).loadWalletData(),
    );
    await show(tester, container, const AddWalletBottomSheet());

    final first = tester.getSemantics(find.bySemanticsLabel('Card design 1'));
    final second = tester.getSemantics(find.bySemanticsLabel('Card design 2'));
    expect(
      first.getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(
      second.getSemanticsData().flagsCollection.isSelected,
      Tristate.isFalse,
    );
    semantics.dispose();
  });

  testWidgets('rating stars are named and 48pt tall', (tester) async {
    final semantics = tester.ensureSemantics();
    final container = await app(tester);
    await show(tester, container, const FeedbackBottomSheet());

    for (final label in ['1 star', '2 stars', '5 stars']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    expect(
      tester.getSize(find.bySemanticsLabel('3 stars')).height,
      greaterThanOrEqualTo(48),
    );
    semantics.dispose();
  });

  testWidgets('category actions are named, 48pt, and delete asks first',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final container = await app(
      tester,
      load: (c) async => c.read(categoriesNotifierProvider),
    );
    await show(tester, container, const ManageCategoriesBottomSheet());
    final name = container.read(categoriesNotifierProvider).first.name;

    final edit = find.bySemanticsLabel('Edit $name');
    final delete = find.bySemanticsLabel('Delete $name');
    expect(tester.getSize(edit).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(delete).width, greaterThanOrEqualTo(48));

    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.text('Delete $name?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      container.read(categoriesNotifierProvider).map((c) => c.name),
      contains(name),
    );
    semantics.dispose();
  });

  testWidgets('tapping a Vault note opens it', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VaultNoteItem(
            note: const VaultNoteModel(
              id: 'n',
              date: '30 September 2026',
              content: 'Locker PIN 4821',
            ),
            onEdit: () => opened++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Locker PIN 4821'));
    await tester.pump();

    expect(opened, 1);
    // Stored as "30 September 2026", shown the way dates read in Zenio.
    expect(find.text('30 September 2026'), findsNothing);
  });

  testWidgets('a long subscription category stays on one line', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currencyCodeProvider.overrideWithValue('INR')],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: SubscriptionCard(
                subscription: SubscriptionModel(
                  id: 's',
                  title: 'Netflix',
                  category: 'Entertainment and streaming services',
                  amount: 649,
                  currency: 'INR',
                  nextBillingDate: DateTime.now().add(const Duration(days: 3)),
                  billingCycle: 'Monthly',
                  iconName: '',
                ),
                isTileExpanded: true,
              ),
            ),
          ),
        ),
      ),
    );

    final category = tester.widget<Text>(
      find.text('Entertainment and streaming services'),
    );
    expect(category.maxLines, 1);
    expect(find.text("You're reminded the day before, at 9 AM."), findsOne);
  });
}
