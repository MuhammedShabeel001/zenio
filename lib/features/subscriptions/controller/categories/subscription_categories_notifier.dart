import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/transactions/domain/models/category_item_model.dart';
import 'package:zenio/shared/services/sqlite_prefs.dart';

part 'subscription_categories_notifier.g.dart';

@Riverpod(keepAlive: true)
class SubscriptionCategoriesNotifier extends _$SubscriptionCategoriesNotifier {
  static const String _storageKey = 'zenio_subscription_categories_v1';
  SqlitePrefs? _prefs;
  Future<void>? _initialLoad;
  bool _loaded = false;

  @override
  List<CategoryItemModel> build() {
    _initialLoad = _initPrefsAndLoad();
    return CategoryItemModel.defaultSubscriptionCategories;
  }

  Future<void> _initPrefsAndLoad() async {
    try {
      final prefs = await ref.watch(sqlitePrefsProvider.future);
      _prefs = prefs;
      if (!prefs.containsKey(_storageKey)) {
        _loaded = true;
        // First run: store the default categories.
        await _saveCategories(CategoryItemModel.defaultSubscriptionCategories);
        return;
      }
      final loaded =
          await prefs.readJsonList(_storageKey, CategoryItemModel.fromJson);
      if (loaded.isNotEmpty) {
        state = loaded;
      }
      _loaded = true;
    } catch (_) {
      // Keep default categories in memory if db loading fails
    }
  }

  Future<void> _saveCategories(List<CategoryItemModel> categories) async {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('Local storage is not ready yet.');
    }
    final rawList = categories.map((c) => jsonEncode(c.toJson())).toList();
    await prefs.setStringList(_storageKey, rawList);
  }

  /// Waits for the stored categories before any change, so the in-memory
  /// defaults can never overwrite the user's own categories.
  Future<void> _ready() async {
    await _initialLoad;
    if (!_loaded) {
      throw StateError('Categories could not be loaded.');
    }
  }

  Future<void> resetCategories() async {
    await _ready();
    state = CategoryItemModel.defaultSubscriptionCategories;
    await _saveCategories(state);
  }

  Future<CategoryItemModel> addCategory({
    required String name,
    required String emoji,
  }) async {
    await _ready();
    final newCategory = CategoryItemModel(
      id: 'sub_cat_${DateTime.now().millisecondsSinceEpoch}',
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
    await _ready();
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
    await _ready();
    final updated = state.where((c) => c.id != id).toList();
    state = updated;
    await _saveCategories(updated);
  }
}
