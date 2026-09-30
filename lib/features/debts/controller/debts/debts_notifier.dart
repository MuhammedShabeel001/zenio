import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/debts/controller/debts/debts_state.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/features/debts/domain/repositories/implementations/debts_repository.dart';
import 'package:zenio/features/debts/domain/repositories/interfaces/i_debts_repository.dart';
import 'package:zenio/shared/utils/serial_task_queue.dart';

part 'debts_notifier.g.dart';

@Riverpod(keepAlive: true)
class DebtsNotifier extends _$DebtsNotifier {
  IDebtsRepository? _repository;
  Future<void>? _initialLoad;
  final _writes = SerialTaskQueue();

  @override
  DebtsState build() {
    try {
      _repository = ref.watch(debtsRepositoryRepoProvider);
      _initialLoad = Future.microtask(_loadData);
    } catch (_) {
      // Local storage is still opening; this notifier rebuilds once it is.
      _repository = null;
      _initialLoad = null;
    }
    return DebtsState.initial();
  }

  Future<void> _loadData() async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final list = await repo.getDebts();
      state = state.copyWith(
        totalBalance: _calculateBalance(list),
        debts: list,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadData() async => _loadData();

  void updateFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  double _calculateBalance(List<DebtModel> debts) {
    var balance = 0.0;
    for (final debt in debts) {
      if (debt.isOwed) {
        balance -= debt.amount;
      } else {
        balance += debt.amount;
      }
    }
    return balance;
  }

  /// Applies [change] to the stored list (not the in-memory copy) once the
  /// initial load has finished, then publishes the result.
  Future<void> _mutate(
    List<DebtModel> Function(List<DebtModel> current) change,
  ) {
    return _writes.run(() async {
      final repo = _repository;
      if (repo == null) {
        throw StateError('Local storage is not ready yet.');
      }
      await _initialLoad;
      final updated = change(await repo.getDebts());
      await repo.saveDebts(updated);
      state = state.copyWith(
        totalBalance: _calculateBalance(updated),
        debts: updated,
      );
    });
  }

  Future<void> addDebt(DebtModel debt) {
    return _mutate((current) => [...current, debt]);
  }

  Future<void> updateDebt(DebtModel debt) {
    return _mutate(
      (current) => current.map((d) => d.id == debt.id ? debt : d).toList(),
    );
  }

  Future<void> deleteDebt(String id) {
    return _mutate(
      (current) => current.where((debt) => debt.id != id).toList(),
    );
  }
}
