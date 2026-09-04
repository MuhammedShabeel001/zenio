class CategoryItemModel {
  const CategoryItemModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.isDefault = false,
  });

  factory CategoryItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🏷️',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String emoji;
  final bool isDefault;

  CategoryItemModel copyWith({
    String? id,
    String? name,
    String? emoji,
    bool? isDefault,
  }) {
    return CategoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'isDefault': isDefault,
    };
  }

  static const List<CategoryItemModel> defaultCategories = [
    CategoryItemModel(
      id: 'cat_food',
      name: 'Food',
      emoji: '🍔',
      isDefault: true,
    ),
    CategoryItemModel(
      id: 'cat_shopping',
      name: 'Shopping',
      emoji: '🛍️',
      isDefault: true,
    ),
    CategoryItemModel(
      id: 'cat_travel',
      name: 'Travel',
      emoji: '🚗',
      isDefault: true,
    ),
    CategoryItemModel(
      id: 'cat_entertainment',
      name: 'Entertainment',
      emoji: '🎬',
      isDefault: true,
    ),
    CategoryItemModel(
      id: 'cat_bills',
      name: 'Bills',
      emoji: '💡',
      isDefault: true,
    ),
  ];
}
