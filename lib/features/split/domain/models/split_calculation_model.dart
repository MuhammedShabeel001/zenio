import 'package:freezed_annotation/freezed_annotation.dart';

part 'split_calculation_model.freezed.dart';
part 'split_calculation_model.g.dart';

enum SplitMode { equal, trip }

@freezed
abstract class SplitCalculationModel with _$SplitCalculationModel {
  const factory SplitCalculationModel({
    required double billAmount,
    required int peopleCount,
    required int returnersCount,
    required SplitMode mode,
  }) = _SplitCalculationModel;

  factory SplitCalculationModel.fromJson(Map<String, dynamic> json) =>
      _$SplitCalculationModelFromJson(json);
}
