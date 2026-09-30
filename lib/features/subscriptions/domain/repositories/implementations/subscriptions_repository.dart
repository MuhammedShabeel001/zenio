import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/domain/repositories/interfaces/i_subscriptions_repository.dart';
import 'package:zenio/shared/providers/providers.dart';

part 'subscriptions_repository.g.dart';

class SubscriptionsRepository implements ISubscriptionsRepository {
  SubscriptionsRepository(this._prefs);

  final SqlitePrefs _prefs;

  static const String _balanceKey = 'subscriptions_page_balance_v3';
  static const String _subscriptionsKey = 'subscriptions_list_key_v3';

  @override
  Future<double> getSubscriptionsBalance() async {
    return _prefs.getDouble(_balanceKey) ?? 0;
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptions() {
    return _prefs.readJsonList(_subscriptionsKey, SubscriptionModel.fromJson);
  }

  @override
  Future<void> saveSubscriptions(
    List<SubscriptionModel> subscriptions,
  ) async {
    final jsonList =
        subscriptions.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_subscriptionsKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
ISubscriptionsRepository subscriptionsRepositoryRepo(Ref ref) {
  final prefs = ref.watch(sqlitePrefsProvider).valueOrNull;
  if (prefs == null) {
    throw StateError('Local storage is not ready yet.');
  }
  return SubscriptionsRepository(prefs);
}
