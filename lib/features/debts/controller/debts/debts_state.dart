import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/features/debts/domain/repositories/implementations/debts_repository.dart';

part 'debts_state.freezed.dart';

@freezed
abstract class DebtsState with _$DebtsState {
  const factory DebtsState({
    required double totalBalance,
    required List<DebtModel> debts,
    required String selectedFilter,
    required bool isLoading,
    String? errorMessage,
  }) = _DebtsState;

  factory DebtsState.initial() => const DebtsState(
        totalBalance: -268.01,
        debts: defaultDebtsList,
        selectedFilter: 'Debts',
        isLoading: false,
      );
}
