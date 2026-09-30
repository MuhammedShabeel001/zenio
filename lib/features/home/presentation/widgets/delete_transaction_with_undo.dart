import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/presentation/widgets/transaction_amount.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/widgets/money.dart';
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
  var undone = false;
  // Says what went, e.g. "Food · −₹420.00 deleted".
  final amount = Money.signed(
    deleted.amount,
    symbol: ref.read(currencySymbolProvider),
    direction: moneyDirectionOf(
      deleted.resolvedKind,
      isIncome: deleted.isIncome,
    ),
  );
  ZenioSnackBar.show(
    context,
    message: '${deleted.title} · $amount deleted',
    duration: _undoWindow,
    actionLabel: 'Undo',
    onAction: () async {
      // Undo stays tappable while the snack bar slides away; a second tap
      // would try to restore it again and report a failure.
      if (undone) return;
      undone = true;
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
