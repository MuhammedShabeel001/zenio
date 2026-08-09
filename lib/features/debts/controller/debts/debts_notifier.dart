import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/debts/controller/debts/debts_state.dart';
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
}
