import 'package:zenio/shared/providers/providers.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/domain/repositories/interfaces/i_subscriptions_repository.dart';

part 'subscriptions_repository.g.dart';

const List<SubscriptionModel> defaultSubscriptionsList = [
  SubscriptionModel(
    id: '1',
    title: 'Spotify Premium',
    category: 'Entertainment',
    amount: 120,
    currency: 'INR',
    dueInText: 'Within 3 days',
    iconName: 'music',
  ),
  SubscriptionModel(
    id: '2',
    title: 'Netflix 4K',
    category: 'Entertainment',
    amount: 649,
    currency: 'INR',
    dueInText: 'In 5 days',
    iconName: 'music',
  ),
  SubscriptionModel(
    id: '3',
    title: 'YouTube Premium',
    category: 'Entertainment',
    amount: 149,
    currency: 'INR',
    dueInText: 'In 12 days',
    iconName: 'music',
  ),
  SubscriptionModel(
    id: '4',
    title: 'Apple iCloud+',
    category: 'Utilities',
    amount: 219,
    currency: 'INR',
    dueInText: 'In 18 days',
    iconName: 'music',
  ),
  SubscriptionModel(
    id: '5',
    title: 'ChatGPT Plus',
    category: 'Productivity',
    amount: 1999,
    currency: 'INR',
    dueInText: 'In 22 days',
    iconName: 'music',
  ),
  SubscriptionModel(
    id: '6',
    title: 'Amazon Prime',
    category: 'Entertainment',
    amount: 299,
    currency: 'INR',
    dueInText: 'In 25 days',
    iconName: 'music',
  ),
  SubscriptionModel(
    id: '7',
    title: 'Figma Pro',
    category: 'Productivity',
    amount: 1250,
    currency: 'INR',
    dueInText: 'In 28 days',
    iconName: 'music',
  ),
  SubscriptionModel(
    id: '8',
    title: 'Gym Membership',
    category: 'Health & Fitness',
    amount: 1500,
    currency: 'INR',
    dueInText: 'In 30 days',
    iconName: 'music',
  ),
];

class SubscriptionsRepository implements ISubscriptionsRepository {
  SubscriptionsRepository(this._prefs);

  final SqlitePrefs? _prefs;

  static const String _balanceKey = 'subscriptions_page_balance_v3';
  static const String _subscriptionsKey = 'subscriptions_list_key_v3';

  @override
  Future<double> getSubscriptionsBalance() async {
    final prefs = _prefs;
    if (prefs == null) return 2678.01;
    final balance = prefs.getDouble(_balanceKey);
    if (balance != null) {
      return balance;
    }
    const defaultBalance = 2678.01;
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
