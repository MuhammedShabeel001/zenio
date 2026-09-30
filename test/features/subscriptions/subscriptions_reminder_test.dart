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
  testWidgets(
      'a reminder shows its subscription even if the last filter hides it',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Zenio',
      packageName: 'com.aurea.zenio',
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
    final container = TestStorage.create().container(
      overrides: [
        subscriptionsRepositoryRepoProvider.overrideWith((ref) => repository),
      ],
    );
    await tester.runAsync(() => container.read(sqlitePrefsProvider.future));
    container.read(subscriptionsNotifierProvider.notifier).updateFilter(
          'Weekly',
        );
    await tester.pump();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SubscriptionsScreenMobile(initialExpandedId: 's14'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(subscriptionsNotifierProvider).selectedFilter, 'All');
    expect(find.text('Service 14').hitTestable(), findsOneWidget);
  });
}
