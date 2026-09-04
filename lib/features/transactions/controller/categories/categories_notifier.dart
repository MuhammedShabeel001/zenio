import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/transactions/domain/models/category_item_model.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

part 'categories_notifier.g.dart';

@Riverpod(keepAlive: true)
class CategoriesNotifier extends _$CategoriesNotifier {
  static const String _storageKey = 'zenio_transaction_categories_v1';
  SqlitePrefs? _prefs;

  @override
  List<CategoryItemModel> build() {
    _initPrefsAndLoad();
    return CategoryItemModel.defaultCategories;
  }

  Future<void> _initPrefsAndLoad() async {
    try {
      final prefs = await ref.watch(sqlitePrefsProvider.future);
      _prefs = prefs;
      final rawList = prefs.getStringList(_storageKey);
      if (rawList != null && rawList.isNotEmpty) {
        final loaded = rawList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return CategoryItemModel.fromJson(map);
        }).toList();
        state = loaded;
      } else {
        // Save initial default categories
        await _saveCategories(CategoryItemModel.defaultCategories);
      }
    } catch (_) {
      // Keep default categories in memory if db loading fails
    }
  }

  Future<void> _saveCategories(List<CategoryItemModel> categories) async {
    if (_prefs == null) {
      try {
        _prefs = await ref.read(sqlitePrefsProvider.future);
      } catch (_) {
        return;
      }
    }
    final rawList = categories.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs?.setStringList(_storageKey, rawList);
  }

  Future<CategoryItemModel> addCategory({
    required String name,
    required String emoji,
  }) async {
    final newCategory = CategoryItemModel(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      emoji: emoji.trim().isEmpty ? '🏷️' : emoji.trim(),
    );

    final updated = [...state, newCategory];
    state = updated;
    await _saveCategories(updated);
    return newCategory;
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String emoji,
  }) async {
    final updated = state.map((c) {
      if (c.id == id) {
        return c.copyWith(
          name: name.trim(),
          emoji: emoji.trim().isEmpty ? c.emoji : emoji.trim(),
        );
      }
      return c;
    }).toList();

    state = updated;
    await _saveCategories(updated);
  }

  Future<void> deleteCategory(String id) async {
    final updated = state.where((c) => c.id != id).toList();
    state = updated;
    await _saveCategories(updated);
  }

  Future<void> resetToDefaults() async {
    state = CategoryItemModel.defaultCategories;
    await _saveCategories(CategoryItemModel.defaultCategories);
  }
}
