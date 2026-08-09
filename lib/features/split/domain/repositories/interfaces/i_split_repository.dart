import 'package:zenio/features/split/domain/models/split_calculation_model.dart';

abstract class ISplitRepository {
  Future<SplitCalculationModel> getSavedSplit();
  Future<void> saveSplit(SplitCalculationModel split);
}
