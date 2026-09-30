import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

/// How long Undo stays available after a delete, as for transactions.
const Duration undoWindow = Duration(seconds: 5);

/// Deletes straight away with [delete], then says what went ("[label]
/// deleted") and offers Undo for [undoWindow], which runs [restore]. The
/// same pattern as deleting a transaction.
Future<void> deleteWithUndo(
  BuildContext context, {
  required String label,
  required Future<void> Function() delete,
  required Future<void> Function() restore,
}) async {
  try {
    await delete();
  } catch (_) {
    if (!context.mounted) return;
    ZenioSnackBar.show(
      context,
      message: "Couldn't delete $label. Please try again.",
      type: ZenioSnackBarType.error,
    );
    return;
  }
  await HapticFeedback.lightImpact();
  if (!context.mounted) return;

  var undone = false;
  ZenioSnackBar.show(
    context,
    message: '$label deleted',
    duration: undoWindow,
    actionLabel: 'Undo',
    onAction: () async {
      // Undo stays tappable while the snack bar slides away.
      if (undone) return;
      undone = true;
      try {
        await restore();
      } catch (_) {
        if (!context.mounted) return;
        ZenioSnackBar.show(
          context,
          message: "Couldn't restore $label.",
          type: ZenioSnackBarType.error,
        );
      }
    },
  );
}
