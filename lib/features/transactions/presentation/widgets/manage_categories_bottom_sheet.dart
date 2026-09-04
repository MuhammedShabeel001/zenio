import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/transactions/domain/models/category_item_model.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class ManageCategoriesBottomSheet extends ConsumerStatefulWidget {
  const ManageCategoriesBottomSheet({this.onCategorySelected, super.key});

  final ValueChanged<CategoryItemModel>? onCategorySelected;

  static Future<CategoryItemModel?> show(BuildContext context) {
    return showModalBottomSheet<CategoryItemModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManageCategoriesBottomSheet(
        onCategorySelected: (cat) => Navigator.of(context).pop(cat),
      ),
    );
  }

  @override
  ConsumerState<ManageCategoriesBottomSheet> createState() =>
      _ManageCategoriesBottomSheetState();
}

class _ManageCategoriesBottomSheetState
    extends ConsumerState<ManageCategoriesBottomSheet> {
  bool _isCreatingOrEditing = false;
  CategoryItemModel? _editingCategory;

  late TextEditingController _nameController;
  late TextEditingController _customEmojiController;
  String _selectedEmoji = '🍔';

  static const List<String> _popularEmojis = [
    '🍔', '🍕', '☕', '🍷', '🍦', '🛒', '🛍️', '🚗',
    '🚕', '⛽', '🚌', '✈️', '🎬', '🎮', '🎵', '⚽',
    '🏋️', '💊', '🏥', '💡', '🏠', '📱', '💻', '📚',
    '💼', '💰', '🎁', '🐾', '💈', '🏖️', '👶', '🛠️',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _customEmojiController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customEmojiController.dispose();
    super.dispose();
  }

  void _startCreate() {
    setState(() {
      _isCreatingOrEditing = true;
      _editingCategory = null;
      _nameController.clear();
      _customEmojiController.clear();
      _selectedEmoji = '🍔';
    });
  }

  void _startEdit(CategoryItemModel category) {
    setState(() {
      _isCreatingOrEditing = true;
      _editingCategory = category;
      _nameController.text = category.name;
      _customEmojiController.text = category.emoji;
      _selectedEmoji = category.emoji;
    });
  }

  void _cancelEditOrCreate() {
    setState(() {
      _isCreatingOrEditing = false;
      _editingCategory = null;
      _nameController.clear();
      _customEmojiController.clear();
    });
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final emoji = _customEmojiController.text.trim().isNotEmpty
        ? _customEmojiController.text.trim()
        : _selectedEmoji;

    final notifier = ref.read(categoriesNotifierProvider.notifier);

    if (_editingCategory != null) {
      await notifier.updateCategory(
        id: _editingCategory!.id,
        name: name,
        emoji: emoji,
      );
      setState(() {
        _isCreatingOrEditing = false;
        _editingCategory = null;
      });
    } else {
      final created = await notifier.addCategory(
        name: name,
        emoji: emoji,
      );
      widget.onCategorySelected?.call(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesNotifierProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle Indicator
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sheet Title & Top Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isCreatingOrEditing
                      ? (_editingCategory != null
                          ? 'Edit Category'
                          : 'New Category')
                      : 'Categories',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),
                if (!_isCreatingOrEditing)
                  GestureDetector(
                    onTap: _startCreate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _cancelEditOrCreate,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Content: Either Form or List
            if (_isCreatingOrEditing)
              _buildCategoryForm()
            else
              _buildCategoryList(categories),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryItemModel> categories) {
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'No categories yet. Tap + Add to create one.',
            style: TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
          ),
        ),
      );
    }

    return Column(
      children: categories.map((category) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // Emoji Circle
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Category Name
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
              ),

              // Edit Action
              GestureDetector(
                onTap: () => _startEdit(category),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Assets.icons.edit.svg(
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF8E8E93),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Delete Action
              GestureDetector(
                onTap: () async {
                  await ref
                      .read(categoriesNotifierProvider.notifier)
                      .deleteCategory(category.id);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Assets.icons.delete.svg(
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFDD3D34),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryForm() {
    final currentEmoji = _customEmojiController.text.trim().isNotEmpty
        ? _customEmojiController.text.trim()
        : _selectedEmoji;
    final currentName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Category Name';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live Preview Chip
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    currentName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Name Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
            decoration: const InputDecoration(
              hintText: 'Category Name (e.g. Groceries)',
              hintStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9E9EA5),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Select Emoji Header
        const Text(
          'Select Emoji',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8E8E93),
          ),
        ),
        const SizedBox(height: 10),

        // Emoji Grid
        Container(
          height: 160,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: GridView.builder(
            itemCount: _popularEmojis.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final emoji = _popularEmojis[index];
              final isSelected = _selectedEmoji == emoji &&
                  _customEmojiController.text.trim().isEmpty;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedEmoji = emoji;
                    _customEmojiController.clear();
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: const Color(0xFF10B981), width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Custom Emoji Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _customEmojiController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'Or type custom emoji (e.g. 🎯)',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Color(0xFF9E9EA5),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Save Button
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _saveCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              _editingCategory != null ? 'Update Category' : 'Save Category',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
