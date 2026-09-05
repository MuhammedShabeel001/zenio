import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/split/controller/split/split_state.dart';
import 'package:zenio/features/split/domain/models/split_calculation_model.dart';
import 'package:zenio/features/split/domain/repositories/implementations/split_repository.dart';

part 'split_notifier.g.dart';

@Riverpod(keepAlive: true)
class SplitNotifier extends _$SplitNotifier {
  @override
  SplitState build() {
    _loadData();
    return SplitState.initial();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(splitRepositoryRepoProvider);
      final saved = await repo.getSavedSplit();
      state = state.copyWith(
        billAmount: saved.billAmount,
        peopleCount: saved.peopleCount,
        returnersCount: saved.returnersCount,
        mode: saved.mode,
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

  void setBillAmount(double amount) {
    state = state.copyWith(billAmount: amount);
    _persist();
  }

  void setMode(SplitMode mode) {
    state = state.copyWith(mode: mode);
    _persist();
  }

  void incrementPeople() {
    state = state.copyWith(peopleCount: state.peopleCount + 1);
    _persist();
  }

  void decrementPeople() {
    if (state.peopleCount > 1) {
      final newCount = state.peopleCount - 1;
      final newReturners =
          state.returnersCount > newCount ? newCount : state.returnersCount;
      state = state.copyWith(
        peopleCount: newCount,
        returnersCount: newReturners,
      );
      _persist();
    }
  }

  void incrementReturners() {
    if (state.returnersCount < state.peopleCount) {
      state = state.copyWith(returnersCount: state.returnersCount + 1);
      _persist();
    }
  }

  void decrementReturners() {
    if (state.returnersCount > 1) {
      state = state.copyWith(returnersCount: state.returnersCount - 1);
      _persist();
    }
  }

  Future<void> _persist() async {
    try {
      final repo = ref.read(splitRepositoryRepoProvider);
      await repo.saveSplit(
        SplitCalculationModel(
          billAmount: state.billAmount,
          peopleCount: state.peopleCount,
          returnersCount: state.returnersCount,
          mode: state.mode,
        ),
      );
    } catch (_) {}
  }
}
