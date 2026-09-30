import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

/// How long the Undo action stays available.
const Duration _undoWindow = Duration(seconds: 5);

/// Deletes the transaction straight away and offers to undo it. Undo stores
/// the same transaction again, so it returns to its place in the history and
/// wallet balances follow automatically.
Future<void> deleteTransactionWithUndo(
  BuildContext context,
  WidgetRef ref,
  String transactionId,
) async {
  final notifier = ref.read(homeNotifierProvider.notifier);
  final deleted = ref
      .read(homeNotifierProvider)
      .transactions
      .where((tx) => tx.id == transactionId)
      .firstOrNull;
  if (deleted == null) return;

  try {
    await notifier.deleteTransaction(transactionId);
  } catch (_) {
    if (!context.mounted) return;
    ZenioSnackBar.show(
      context,
      message: "Couldn't delete the transaction. Please try again.",
      type: ZenioSnackBarType.error,
    );
    return;
  }
  await HapticFeedback.lightImpact();

  if (!context.mounted) return;
  ZenioSnackBar.show(
    context,
    message: 'Transaction deleted',
    duration: _undoWindow,
    actionLabel: 'Undo',
    onAction: () async {
      try {
        await notifier.addTransaction(deleted);
      } catch (_) {
        if (!context.mounted) return;
        ZenioSnackBar.show(
          context,
          message: "Couldn't restore the transaction.",
          type: ZenioSnackBarType.error,
        );
      }
    },
  );
}
