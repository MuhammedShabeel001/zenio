import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/subscriptions/controller/subscriptions/subscriptions_state.dart';
import 'package:zenio/features/subscriptions/domain/billing_schedule.dart';
import 'package:zenio/features/subscriptions/domain/models/subscription_model.dart';
import 'package:zenio/features/subscriptions/domain/repositories/implementations/subscriptions_repository.dart';
import 'package:zenio/features/subscriptions/domain/repositories/interfaces/i_subscriptions_repository.dart';
import 'package:zenio/shared/services/notification_service.dart';
import 'package:zenio/shared/utils/serial_task_queue.dart';

part 'subscriptions_notifier.g.dart';

@Riverpod(keepAlive: true)
class SubscriptionsNotifier extends _$SubscriptionsNotifier {
  ISubscriptionsRepository? _repository;
  Future<void>? _initialLoad;
  final _writes = SerialTaskQueue();

  @override
  SubscriptionsState build() {
    try {
      _repository = ref.watch(subscriptionsRepositoryRepoProvider);
      _initialLoad = Future.microtask(_loadData);
    } catch (_) {
      // Local storage is still opening; this notifier rebuilds once it is.
      _repository = null;
      _initialLoad = null;
    }
    return SubscriptionsState.initial();
  }

  /// Loads the subscriptions, moving billing dates that have passed on to
  /// the next cycle. With [syncReminders], the scheduled reminders are made
  /// to match (on first load and after every change).
  Future<void> _loadData({bool syncReminders = true}) async {
    final repo = _repository;
    if (repo == null) return;
    state = state.copyWith(isLoading: true);
    try {
      var list = await repo.getSubscriptions();

      final now = DateTime.now();
      final rolled = [for (final sub in list) rolledForward(sub, now)];
      if (!listEquals(rolled, list)) {
        await _writes.run(() async {
          // Roll the stored list, not this copy, in case it changed since.
          final stored = await repo.getSubscriptions();
          await repo.saveSubscriptions(
            [for (final sub in stored) rolledForward(sub, now)],
          );
        });
        list = await repo.getSubscriptions();
      }

      final filteredList = _filterSubscriptions(list, state.selectedFilter);
      final balance = _calculateTotalBalance(filteredList);

      state = state.copyWith(
        totalBalance: balance,
        subscriptions: filteredList,
        isLoading: false,
        errorMessage: null,
      );

      if (syncReminders) {
        unawaited(
          ref
              .read(notificationServiceProvider)
              .syncSubscriptionReminders(list),
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadData() async => _loadData();

  List<SubscriptionModel> _filterSubscriptions(
    List<SubscriptionModel> allSubscriptions,
    String filter,
  ) {
    if (filter.toLowerCase() == 'all') {
      return allSubscriptions;
    }
    return allSubscriptions.where((sub) {
      return sub.billingCycle.toLowerCase() == filter.toLowerCase();
    }).toList();
  }

  double _calculateTotalBalance(List<SubscriptionModel> subs) {
    double total = 0;
    for (final sub in subs) {
      total += sub.amount;
    }
    return total;
  }

  void updateFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
    unawaited(_loadData(syncReminders: false));
  }

  /// Applies [change] to the stored list once the initial load has finished,
  /// one write at a time, then refreshes the visible (filtered) list.
  Future<void> _initialLoadThen(Future<void> Function() action) async {
    await _initialLoad;
    await action();
  }

  Future<void> _mutate(
    List<SubscriptionModel> Function(List<SubscriptionModel> current) change,
  ) {
    // Wait for the initial load outside the queue: that load queues its own
    // rollover write, so waiting inside would deadlock.
    return _initialLoadThen(
      () => _writes.run(() async {
        final repo = _repository;
        if (repo == null) {
          throw StateError('Local storage is not ready yet.');
        }
        await repo.saveSubscriptions(change(await repo.getSubscriptions()));
      }),
    );
  }

  /// Anchors the renewal day to the chosen billing date and moves it on if
  /// that date has already passed.
  SubscriptionModel _prepared(
    SubscriptionModel sub, {
    SubscriptionModel? previous,
  }) {
    // Keep the renewal day (e.g. the 31st after a February renewal on the
    // 28th) unless the user picked a different date.
    final sameDate = previous != null &&
        DateUtils.isSameDay(previous.nextBillingDate, sub.nextBillingDate);
    final billingDay = sameDate
        ? (previous.billingDay ?? previous.nextBillingDate.day)
        : sub.nextBillingDate.day;
    return rolledForward(sub.copyWith(billingDay: billingDay), DateTime.now());
  }

  Future<void> deleteSubscription(String id) async {
    await _mutate((all) => all.where((sub) => sub.id != id).toList());
    await _loadData();
  }

  Future<void> addSubscription(SubscriptionModel sub) async {
    await _mutate((all) => [...all, _prepared(sub)]);
    await _loadData();
  }

  Future<void> updateSubscription(SubscriptionModel sub) async {
    await _mutate(
      (all) => all
          .map((s) => s.id == sub.id ? _prepared(sub, previous: s) : s)
          .toList(),
    );
    await _loadData();
  }
}
