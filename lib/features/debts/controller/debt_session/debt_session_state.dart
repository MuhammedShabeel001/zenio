import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/debts/domain/models/debt_session_model.dart';

part 'debt_session_state.freezed.dart';

@freezed
abstract class DebtSessionState with _$DebtSessionState {
  const factory DebtSessionState({
    @Default([]) List<DebtSessionModel> debts,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _DebtSessionState;

  factory DebtSessionState.initial() => const DebtSessionState(
        isLoading: true,
      );
}
