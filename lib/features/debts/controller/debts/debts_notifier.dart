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

  void updateFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
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

    final newBalance = state.totalBalance + target.amount;
    state = state.copyWith(
      totalBalance: newBalance,
      debts: updated,
    );
  }
}
