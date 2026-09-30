import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/split/controller/split/split_state.dart';
import 'package:zenio/features/split/domain/models/split_calculation_model.dart';
import 'package:zenio/features/split/domain/repositories/implementations/split_repository.dart';
import 'package:zenio/features/split/domain/repositories/interfaces/i_split_repository.dart';

part 'split_notifier.g.dart';

@Riverpod(keepAlive: true)
class SplitNotifier extends _$SplitNotifier {
  ISplitRepository? _repository;
  Future<void>? _initialLoad;
  bool _loaded = false;
  Timer? _persistTimer;

  @override
  SplitState build() {
    _loaded = false;
    ref.onDispose(() {
      if (_persistTimer?.isActive ?? false) {
        _persistTimer!.cancel();
        unawaited(_persist());
      }
    });
    try {
      _repository = ref.watch(splitRepositoryRepoProvider);
      _initialLoad = Future.microtask(_loadData);
    } catch (_) {
      // Local storage is still opening; this notifier rebuilds once it is.
      _repository = null;
      _initialLoad = null;
    }
    return SplitState.initial();
  }

  Future<void> _loadData() async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final saved = await repo.getSavedSplit();
      state = state.copyWith(
        billAmount: saved.billAmount,
        peopleCount: saved.peopleCount,
        returnersCount: saved.returnersCount,
        mode: saved.mode,
        isLoading: false,
        errorMessage: null,
      );
      _loaded = true;
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
    _schedulePersist();
  }

  void setMode(SplitMode mode) {
    state = state.copyWith(mode: mode);
    _schedulePersist();
  }

  void incrementPeople() {
    state = state.copyWith(peopleCount: state.peopleCount + 1);
    _schedulePersist();
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
      _schedulePersist();
    }
  }

  void incrementReturners() {
    if (state.returnersCount < state.peopleCount) {
      state = state.copyWith(returnersCount: state.returnersCount + 1);
      _schedulePersist();
    }
  }

  void decrementReturners() {
    if (state.returnersCount > 1) {
      state = state.copyWith(returnersCount: state.returnersCount - 1);
      _schedulePersist();
    }
  }

  /// Saves shortly after the last change rather than on every keystroke.
  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_persist()),
    );
  }

  Future<void> _persist() async {
    await _initialLoad;
    // Never overwrite the saved split with defaults it was not loaded into.
    final repo = _repository;
    if (!_loaded || repo == null) return;
    try {
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
