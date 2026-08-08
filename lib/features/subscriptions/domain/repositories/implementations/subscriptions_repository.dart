import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/domain/repositories/interfaces/i_subscriptions_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'subscriptions_repository.g.dart';

class SubscriptionsRepository implements ISubscriptionsRepository {
  SubscriptionsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _balanceKey = 'subscriptions_page_balance';
  static const String _subscriptionsKey = 'subscriptions_list_key';

  @override
  Future<double> getSubscriptionsBalance() async {
    final balance = _prefs.getDouble(_balanceKey);
    if (balance != null) {
      return balance;
    }
    const defaultBalance = 2678.01;
    await _prefs.setDouble(_balanceKey, defaultBalance);
    return defaultBalance;
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptions() async {
    final rawJsonList = _prefs.getStringList(_subscriptionsKey);
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

    final defaultList = [
      const SubscriptionModel(
        id: '1',
        title: 'Spotify',
        category: 'Entertainment',
        amount: 120,
        currency: 'INR',
        dueInText: 'Within 3 days',
        iconName: 'music',
      ),
      const SubscriptionModel(
        id: '2',
        title: 'Spotify',
        category: 'Entertainment',
        amount: 120,
        currency: 'INR',
        dueInText: 'Within 3 days',
        iconName: 'music',
      ),
    ];
    await saveSubscriptions(defaultList);
    return defaultList;
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
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized yet');
  }
  return SubscriptionsRepository(prefs);
}
