import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/debts/controller/debts/debts_notifier.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/domain/repositories/implementations/subscriptions_repository.dart';
import 'package:zenio/features/subscriptions/domain/repositories/interfaces/i_subscriptions_repository.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';
import 'package:zenio/shared/widgets/delete_with_undo.dart';

import '../../helpers/test_storage.dart';

DebtModel _debt(String id) => DebtModel(
      id: id,
      personName: id,
      date: '01 September 2026',
      amount: 100,
      currency: 'INR',
      isOwed: true,
      iconName: '',
    );

SubscriptionModel _sub(String id) => SubscriptionModel(
      id: id,
      title: id,
      category: 'Streaming',
      amount: 100,
      currency: 'INR',
      nextBillingDate: DateTime.now().add(const Duration(days: 10)),
      billingCycle: 'Monthly',
      iconName: '',
    );

class _Subscriptions implements ISubscriptionsRepository {
  _Subscriptions(this.items);

  List<SubscriptionModel> items;

  @override
  Future<List<SubscriptionModel>> getSubscriptions() async => List.of(items);

  @override
  Future<void> saveSubscriptions(List<SubscriptionModel> subscriptions) async =>
      items = List.of(subscriptions);

  @override
  Future<double> getSubscriptionsBalance() async => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('says what was deleted and Undo restores it', (tester) async {
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final log = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => deleteWithUndo(
                context,
                label: 'Netflix',
                delete: () async => log.add('delete'),
                restore: () async => log.add('restore'),
              ),
              child: const Text('Delete'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Netflix deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(log, ['delete', 'restore']);
  });

  testWidgets('a failed delete says so and offers no Undo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => deleteWithUndo(
                context,
                label: 'Netflix',
                delete: () async => throw StateError('disk full'),
                restore: () async {},
              ),
              child: const Text('Delete'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't delete Netflix. Please try again."), findsOne);
    expect(find.text('Undo'), findsNothing);
  });

  test('a deleted debt comes back to its place', () async {
    final storage = TestStorage.create();
    await storage.putKeyValue(
      'debts_list_key_v2',
      jsonEncode([
        for (final id in ['a', 'b', 'c']) jsonEncode(_debt(id).toJson()),
      ]),
    );
    final container = storage.container();
    await container.read(sqlitePrefsProvider.future);
    final notifier = container.read(debtsNotifierProvider.notifier);
    await notifier.loadData();

    await notifier.deleteDebt('b');
    await notifier.restoreDebt(_debt('b'), 1);
    // Undo tapped twice restores once.
    await notifier.restoreDebt(_debt('b'), 1);

    expect(
      container.read(debtsNotifierProvider).debts.map((d) => d.id),
      ['a', 'b', 'c'],
    );
  });

  test('a deleted subscription comes back to its place', () async {
    final repository = _Subscriptions([_sub('a'), _sub('b'), _sub('c')]);
    final container = ProviderContainer(
      overrides: [
        subscriptionsRepositoryRepoProvider.overrideWith((ref) => repository),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(subscriptionsNotifierProvider.notifier);
    await notifier.loadData();

    await notifier.deleteSubscription('b');
    await notifier.restoreSubscription(_sub('b'), 1);

    expect(repository.items.map((s) => s.id), ['a', 'b', 'c']);
  });
}
