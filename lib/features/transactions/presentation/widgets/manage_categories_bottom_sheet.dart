import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/subscriptions/controller/categories/subscription_categories_notifier.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/transactions/domain/models/category_item_model.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class ManageCategoriesBottomSheet extends ConsumerStatefulWidget {
  const ManageCategoriesBottomSheet({
    this.onCategorySelected,
    this.isSubscription = false,
    super.key,
  });

  final ValueChanged<CategoryItemModel>? onCategorySelected;
  final bool isSubscription;

  static Future<CategoryItemModel?> show(
    BuildContext context, {
    bool isSubscription = false,
  }) {
    return showModalBottomSheet<CategoryItemModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManageCategoriesBottomSheet(
        isSubscription: isSubscription,
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
    '🍔', '🍕', '☕', '🍷', '🍦', '🛒', '🛍️',
    '🚗', '⛽', '🚌', '✈️', '🏠', '💡', '📱',
    '🎬', '🎮', '🎵', '⚽', '🏋️', '💊', '🏥',
    '💻', '📚', '💼', '💰', '🎁', '🐾', '🏖️',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _customEmojiController = TextEditingController();
    _selectedEmoji = widget.isSubscription ? '🎬' : '🍔';
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
      _selectedEmoji = widget.isSubscription ? '🎬' : '🍔';
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

    if (widget.isSubscription) {
      final notifier =
          ref.read(subscriptionCategoriesNotifierProvider.notifier);
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
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.isSubscription
        ? ref.watch(subscriptionCategoriesNotifierProvider)
        : ref.watch(categoriesNotifierProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 24),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
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
                      behavior: HitTestBehavior.opaque,
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
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content: Either Form or List
            if (_isCreatingOrEditing)
              _buildCategoryForm()
            else
              _buildCategoryList(categories),

            // Keyboard Inset padding
            SizedBox(height: bottomInset),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryItemModel> categories) {
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No categories yet. Tap + Add to create one.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
      );
    }

    return Column(
      children: categories.map((category) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
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
                child: GestureDetector(
                  onTap: () => widget.onCategorySelected?.call(category),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  if (widget.isSubscription) {
                    await ref
                        .read(subscriptionCategoriesNotifierProvider.notifier)
                        .deleteCategory(category.id);
                  } else {
                    await ref
                        .read(categoriesNotifierProvider.notifier)
                        .deleteCategory(category.id);
                  }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Category Name & Emoji Avatar Field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // Avatar circle with current emoji
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    currentEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name input
              Expanded(
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
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Emoji Selection Container
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Emoji',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  // Custom emoji mini-input pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Custom: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          child: TextField(
                            controller: _customEmojiController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: '🎯',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFC7C7CC),
                              ),
                              isDense: true,
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _popularEmojis.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
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
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Save Button
        SizedBox(
          height: 60,
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
              _editingCategory != null ? 'Update category' : 'Save category',
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
