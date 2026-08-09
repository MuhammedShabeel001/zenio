import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zenio/features/split/domain/models/split_calculation_model.dart';

part 'split_state.freezed.dart';

@freezed
abstract class SplitState with _$SplitState {
  const factory SplitState({
    required double billAmount,
    required int peopleCount,
    required int returnersCount,
    required SplitMode mode,
    required bool isLoading,
    String? errorMessage,
  }) = _SplitState;

  const SplitState._();

  factory SplitState.initial() => const SplitState(
        billAmount: 0,
        peopleCount: 4,
        returnersCount: 2,
        mode: SplitMode.equal,
        isLoading: false,
      );

  // Equal Split calculation
  double get eachPersonPay {
    if (peopleCount <= 0) return 0;
    return billAmount / peopleCount;
  }

  // Trip Split calculations
  double get oneWayPay {
    if (peopleCount <= 0) return 0;
    final goingHalf = billAmount / 2.0;
    return goingHalf / peopleCount;
  }

  double get returnersPay {
    if (peopleCount <= 0 || returnersCount <= 0) return 0;
    final goingHalf = billAmount / 2.0;
    final returningHalf = billAmount / 2.0;
    final oneWay = goingHalf / peopleCount;
    final returningShare = returningHalf / returnersCount;
    return oneWay + returningShare;
  }
}
