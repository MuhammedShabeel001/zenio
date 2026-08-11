import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/transactions/controller/transaction_session/transaction_session_state.dart';
import 'package:zenio/features/transactions/domain/models/transaction_session_model.dart';
import 'package:zenio/features/transactions/domain/repositories/implementations/transaction_session_repository.dart';

part 'transaction_session_notifier.g.dart';

@Riverpod(keepAlive: true)
class TransactionSessionNotifier extends _$TransactionSessionNotifier {
  @override
  TransactionSessionState build() {
    _loadSessions();
    return TransactionSessionState.initial();
  }

  Future<void> _loadSessions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(transactionSessionRepositoryRepoProvider);
      final list = await repo.getTransactionSessions();
      state = state.copyWith(
        sessions: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> addTransactionSession(
    TransactionSessionModel transaction,
  ) async {
    try {
      final repo = ref.read(transactionSessionRepositoryRepoProvider);
      await repo.saveTransactionSession(transaction);
      await _loadSessions();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> updateTransactionSession(
    TransactionSessionModel transaction,
  ) async {
    try {
      final repo = ref.read(transactionSessionRepositoryRepoProvider);
      await repo.updateTransactionSession(transaction);
      await _loadSessions();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteTransactionSession(String id) async {
    try {
      final repo = ref.read(transactionSessionRepositoryRepoProvider);
      await repo.deleteTransactionSession(id);
      await _loadSessions();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> clearAllSessions() async {
    try {
      final repo = ref.read(transactionSessionRepositoryRepoProvider);
      await repo.clearAllTransactionSessions();
      await _loadSessions();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}
