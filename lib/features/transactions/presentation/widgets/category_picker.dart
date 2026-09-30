import 'package:flutter/material.dart';
import 'package:zenio/features/transactions/domain/models/category_item_model.dart';
import 'package:zenio/features/transactions/presentation/widgets/manage_categories_bottom_sheet.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';

/// The category chips of the Add and Edit transaction forms, with a link to
/// manage the categories. The same in both, so the forms read alike.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.optional = false,
    super.key,
  });

  final List<CategoryItemModel> categories;

  /// The name of the chosen category, or null for none.
  final String? selected;

  /// Called with the chosen category's name, or null when an [optional]
  /// category is tapped again to clear it.
  final ValueChanged<String?> onSelected;

  /// Whether no category is needed (income). The label says so, and tapping
  /// the chosen category clears it.
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ZenioColors.fieldFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The Manage link's tap area reaches into the row's padding and the
          // gap below, so the row keeps its height.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 1, 6, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    optional ? 'Category (optional)' : 'Category',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ZenioColors.textSecondary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await ManageCategoriesBottomSheet.show(
                      context,
                    );
                    if (picked != null) onSelected(picked.name);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Semantics(
                    button: true,
                    label: 'Manage categories',
                    excludeSemantics: true,
                    // At least 48pt tall to tap, whatever the text size.
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 14,
                              color: ZenioColors.primaryStrong,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Manage',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: ZenioColors.primaryStrong,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Chip(
                      category: category,
                      isSelected: category.name == selected,
                      onTap: () => onSelected(
                        optional && category.name == selected
                            ? null
                            : category.name,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final CategoryItemModel category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: category.name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: ZenioMotion.of(context, ZenioMotion.fast),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? ZenioColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Text(category.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
              ],
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : ZenioColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
