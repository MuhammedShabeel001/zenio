import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/split/domain/models/split_calculation_model.dart';
import 'package:zenio/features/split/domain/repositories/interfaces/i_split_repository.dart';
import 'package:zenio/shared/providers/providers.dart';

part 'split_repository.g.dart';

const SplitCalculationModel defaultSplitData = SplitCalculationModel(
  billAmount: 0,
  peopleCount: 4,
  returnersCount: 2,
  mode: SplitMode.equal,
);

class SplitRepository implements ISplitRepository {
  SplitRepository(this._prefs);

  final SqlitePrefs _prefs;

  static const String _splitKey = 'split_calculation_data_v1';

  @override
  Future<SplitCalculationModel> getSavedSplit() async {
    final saved =
        await _prefs.readJsonObject(_splitKey, SplitCalculationModel.fromJson);
    return saved ?? defaultSplitData;
  }

  @override
  Future<void> saveSplit(SplitCalculationModel split) async {
    await _prefs.setString(_splitKey, jsonEncode(split.toJson()));
  }
}

@Riverpod(keepAlive: true)
ISplitRepository splitRepositoryRepo(Ref ref) {
  final prefs = ref.watch(sqlitePrefsProvider).valueOrNull;
  if (prefs == null) {
    throw StateError('Local storage is not ready yet.');
  }
  return SplitRepository(prefs);
}
