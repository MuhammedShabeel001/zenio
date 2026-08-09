import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/split/domain/models/split_calculation_model.dart';
import 'package:zenio/features/split/domain/repositories/interfaces/i_split_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'split_repository.g.dart';

const SplitCalculationModel defaultSplitData = SplitCalculationModel(
  billAmount: 0,
  peopleCount: 4,
  returnersCount: 2,
  mode: SplitMode.equal,
);

class SplitRepository implements ISplitRepository {
  SplitRepository(this._prefs);

  final SharedPreferences? _prefs;

  static const String _splitKey = 'split_calculation_data_v1';

  @override
  Future<SplitCalculationModel> getSavedSplit() async {
    final prefs = _prefs;
    if (prefs == null) return defaultSplitData;

    final rawJson = prefs.getString(_splitKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final map = jsonDecode(rawJson) as Map<String, dynamic>;
        return SplitCalculationModel.fromJson(map);
      } catch (_) {
        // Fallback to default
      }
    }

    await saveSplit(defaultSplitData);
    return defaultSplitData;
  }

  @override
  Future<void> saveSplit(SplitCalculationModel split) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_splitKey, jsonEncode(split.toJson()));
  }
}

@Riverpod(keepAlive: true)
ISplitRepository splitRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return SplitRepository(prefs);
}
