import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/implementations/money_tracker/money_tracker_repository.dart';
import 'package:zenio/features/home/domain/repositories/interfaces/money_tracker/i_money_tracker_repository.dart';
import 'package:zenio/features/transactions/controller/transactions/transactions_notifier.dart';

/// Transactions that load only when the test lets them.
class _ControlledTransactions implements IMoneyTrackerRepository {
  Completer<List<TransactionModel>> _load = Completer();

  void loads(List<TransactionModel> transactions) {
    _load.complete(transactions);
    _load = Completer();
  }

  void fails() {
    _load.completeError(StateError('The database could not be read.'));
    _load = Completer();
  }

  @override
  Future<List<TransactionModel>> getTransactions() => _load.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('shows loading, not an empty list, until the transactions are in',
      () async {
    final repository = _ControlledTransactions();
    final container = ProviderContainer(
      overrides: [
        moneyTrackerRepositoryRepoProvider.overrideWith((ref) => repository),
      ],
    );
    addTearDown(container.dispose);
    bool isLoading() => container.read(transactionsNotifierProvider).isLoading;

    expect(isLoading(), isTrue, reason: 'before the first load');
    await pumpEventQueue();
    expect(isLoading(), isTrue, reason: 'while loading');

    repository.fails();
    await pumpEventQueue();
    expect(isLoading(), isFalse, reason: 'the screen offers a retry');

    final retry =
        container.read(homeNotifierProvider.notifier).loadMoneyTrackerData();
    expect(isLoading(), isTrue, reason: 'while retrying');

    repository.loads([
      TransactionModel(
        id: 't1',
        title: 'Food',
        date: DateFormat('dd-MM-yyyy').format(DateTime.now()),
        amount: 120,
        currency: 'INR',
        isIncome: false,
        bankName: 'HDFC',
      ),
    ]);
    await retry;
    final state = container.read(transactionsNotifierProvider);
    expect(state.isLoading, isFalse);
    expect(state.transactions.map((t) => t.id), ['t1']);
    expect(state.totalBalance, 120);
  });
}
