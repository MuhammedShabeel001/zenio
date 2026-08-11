import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/debts/controller/debt_session/debt_session_state.dart';
import 'package:zenio/features/debts/domain/models/debt_session_model.dart';
import 'package:zenio/features/debts/domain/repositories/implementations/debt_session_repository.dart';

part 'debt_session_notifier.g.dart';

@Riverpod(keepAlive: true)
class DebtSessionNotifier extends _$DebtSessionNotifier {
  @override
  DebtSessionState build() {
    _loadDebts();
    return DebtSessionState.initial();
  }

  Future<void> _loadDebts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(debtSessionRepositoryRepoProvider);
      final list = await repo.getDebtSessions();
      state = state.copyWith(
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

  Future<void> addDebtSession(DebtSessionModel debt) async {
    try {
      final repo = ref.read(debtSessionRepositoryRepoProvider);
      await repo.saveDebtSession(debt);
      await _loadDebts();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateDebtSession(DebtSessionModel debt) async {
    try {
      final repo = ref.read(debtSessionRepositoryRepoProvider);
      await repo.updateDebtSession(debt);
      await _loadDebts();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteDebtSession(String id) async {
    try {
      final repo = ref.read(debtSessionRepositoryRepoProvider);
      await repo.deleteDebtSession(id);
      await _loadDebts();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> clearAllDebts() async {
    try {
      final repo = ref.read(debtSessionRepositoryRepoProvider);
      await repo.clearAllDebtSessions();
      await _loadDebts();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}
