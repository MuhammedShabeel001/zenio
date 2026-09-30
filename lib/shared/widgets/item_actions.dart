import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';

/// Edit and delete for a list item without swiping: offered to screen
/// readers as custom actions and to everyone through a long press.
class ItemActions extends StatelessWidget {
  const ItemActions({
    required this.child,
    this.onEdit,
    this.onDelete,
    this.deleteLabel = 'Delete',
    this.confirmDeleteTitle,
    super.key,
  });

  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String deleteLabel;

  /// When set, deleting asks for confirmation with this title first (for
  /// items that cannot be restored).
  final String? confirmDeleteTitle;

  Future<void> _delete(BuildContext context) async {
    final title = confirmDeleteTitle;
    if (title != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDD3D34),
              ),
              child: Text(deleteLabel),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    onDelete?.call();
  }

  Future<void> _showMenu(BuildContext context) async {
    final action = await showModalBottomSheet<VoidCallback>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.of(sheetContext).pop(onEdit),
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: ZenioColors.danger,
                ),
                title: Text(
                  deleteLabel,
                  style: const TextStyle(color: ZenioColors.danger),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(() => _delete(context)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (onEdit == null && onDelete == null) return child;
    return Semantics(
      customSemanticsActions: {
        if (onEdit != null) const CustomSemanticsAction(label: 'Edit'): onEdit!,
        if (onDelete != null)
          CustomSemanticsAction(label: deleteLabel): () => _delete(context),
      },
      child: GestureDetector(
        onLongPress: () => _showMenu(context),
        child: child,
      ),
    );
  }
}
