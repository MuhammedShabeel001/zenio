import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/domain/repositories/interfaces/i_subscriptions_repository.dart';
import 'package:zenio/shared/providers/providers.dart';

part 'subscriptions_repository.g.dart';

const List<SubscriptionModel> defaultSubscriptionsList = [];

class SubscriptionsRepository implements ISubscriptionsRepository {
  SubscriptionsRepository(this._prefs);

  final SqlitePrefs? _prefs;

  static const String _balanceKey = 'subscriptions_page_balance_v3';
  static const String _subscriptionsKey = 'subscriptions_list_key_v3';

  @override
  Future<double> getSubscriptionsBalance() async {
    final prefs = _prefs;
    if (prefs == null) return 0.0;
    final balance = prefs.getDouble(_balanceKey);
    if (balance != null) {
      return balance;
    }
    const defaultBalance = 0.0;
    await prefs.setDouble(_balanceKey, defaultBalance);
    return defaultBalance;
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptions() async {
    final prefs = _prefs;
    if (prefs == null) return defaultSubscriptionsList;

    final rawJsonList = prefs.getStringList(_subscriptionsKey);
    if (rawJsonList != null && rawJsonList.isNotEmpty) {
      try {
        return rawJsonList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return SubscriptionModel.fromJson(map);
        }).toList();
      } catch (_) {
        // Fallback to defaults
      }
    }

    await saveSubscriptions(defaultSubscriptionsList);
    return defaultSubscriptionsList;
  }

  @override
  Future<void> saveSubscriptions(
    List<SubscriptionModel> subscriptions,
  ) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final jsonList =
        subscriptions.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_subscriptionsKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
ISubscriptionsRepository subscriptionsRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sqlitePrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return SubscriptionsRepository(prefs);
}
