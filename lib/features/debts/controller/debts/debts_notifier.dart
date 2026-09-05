import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/debts/controller/debts/debts_state.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/features/debts/domain/repositories/implementations/debts_repository.dart';

part 'debts_notifier.g.dart';

@Riverpod(keepAlive: true)
class DebtsNotifier extends _$DebtsNotifier {
  @override
  DebtsState build() {
    _loadData();
    return DebtsState.initial();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(debtsRepositoryRepoProvider);
      final balance = await repo.getDebtsBalance();
      final list = await repo.getDebts();
      state = state.copyWith(
        totalBalance: balance,
        debts: list,
        isLoading: false,
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
    double balance = 0.0;
    for (final debt in debts) {
      if (debt.isOwed) {
        balance -= debt.amount;
      } else {
        balance += debt.amount;
      }
    }
    return balance;
  }

  Future<void> addDebt(DebtModel debt) async {
    final updated = [...state.debts, debt];
    final repo = ref.read(debtsRepositoryRepoProvider);
    await repo.saveDebts(updated);

    final newBalance = _calculateBalance(updated);
    state = state.copyWith(
      totalBalance: newBalance,
      debts: updated,
    );
  }

  Future<void> updateDebt(DebtModel debt) async {
    final updated = state.debts.map((d) => d.id == debt.id ? debt : d).toList();
    final repo = ref.read(debtsRepositoryRepoProvider);
    await repo.saveDebts(updated);

    final newBalance = _calculateBalance(updated);
    state = state.copyWith(
      totalBalance: newBalance,
      debts: updated,
    );
  }

  Future<void> deleteDebt(String id) async {
    final target = state.debts.firstWhere(
      (debt) => debt.id == id,
      orElse: () => const DebtModel(
        id: '',
        personName: '',
        date: '',
        amount: 0,
        currency: 'INR',
        iconName: '',
        isOwed: true,
      ),
    );
    if (target.id.isEmpty) return;

    final updated = state.debts.where((debt) => debt.id != id).toList();
    final repo = ref.read(debtsRepositoryRepoProvider);
    await repo.saveDebts(updated);

    final newBalance = _calculateBalance(updated);
    state = state.copyWith(
      totalBalance: newBalance,
      debts: updated,
    );
  }
}
