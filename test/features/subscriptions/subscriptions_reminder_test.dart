import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_notifier.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/domain/repositories/implementations/subscriptions_repository.dart';
import 'package:zenio/features/subscriptions/domain/repositories/interfaces/i_subscriptions_repository.dart';
import 'package:zenio/features/subscriptions/presentation/subscriptions/subscriptions_mobile.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

import '../../helpers/test_storage.dart';

class _MemorySubscriptions implements ISubscriptionsRepository {
  _MemorySubscriptions(this.items);

  List<SubscriptionModel> items;

  @override
  Future<List<SubscriptionModel>> getSubscriptions() async => items;

  @override
  Future<void> saveSubscriptions(List<SubscriptionModel> subscriptions) async =>
      items = subscriptions;

  @override
  Future<double> getSubscriptionsBalance() async => 0;
}

void main() {
  late ProviderContainer container;

  String filter() =>
      container.read(subscriptionsNotifierProvider).selectedFilter;

  /// Fifteen monthly subscriptions, the filter left on [lastFilter] from an
  /// earlier visit, and a screen that a reminder for "Service 14" opens.
  Future<void> openReminder(
    WidgetTester tester, {
    required String lastFilter,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
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
    final nextMonth = DateTime.now().add(const Duration(days: 20));
    final repository = _MemorySubscriptions([
      for (var i = 1; i <= 15; i++)
        SubscriptionModel(
          id: 's$i',
          title: 'Service $i',
          category: 'Streaming',
          amount: 100,
          currency: 'INR',
          nextBillingDate: nextMonth,
          billingCycle: 'Monthly',
          iconName: '🎬',
        ),
    ]);
    container = TestStorage.create().container(
      overrides: [
        subscriptionsRepositoryRepoProvider.overrideWith((ref) => repository),
      ],
    );
    await tester.runAsync(() => container.read(sqlitePrefsProvider.future));
    container
        .read(subscriptionsNotifierProvider.notifier)
        .updateFilter(lastFilter);
    await tester.pump();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SubscriptionsScreenMobile(
                      initialExpandedId: 's14',
                    ),
                  ),
                ),
                child: const Text('Reminder'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Reminder'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'a reminder shows its subscription even if the last filter hides it, '
      'and the filter comes back afterwards', (tester) async {
    await openReminder(tester, lastFilter: 'Weekly');

    expect(filter(), 'All');
    expect(find.text('Service 14').hitTestable(), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(filter(), 'Weekly');
  });

  testWidgets('a filter the user picks on the reminder screen is kept',
      (tester) async {
    await openReminder(tester, lastFilter: 'Weekly');

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Yearly'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(filter(), 'Yearly');
  });

  testWidgets('a filter that already shows the subscription is left alone',
      (tester) async {
    await openReminder(tester, lastFilter: 'Monthly');

    expect(filter(), 'Monthly');
    expect(find.text('Service 14').hitTestable(), findsOneWidget);
  });
}
