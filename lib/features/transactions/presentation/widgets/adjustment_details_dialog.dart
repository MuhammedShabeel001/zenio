import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/presentation/widgets/delete_transaction_with_undo.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/datetime.dart';
import 'package:zenio/shared/widgets/money.dart';

/// Shows what a balance adjustment did. Adjustments only exist to set a
/// wallet's balance and cannot be edited, so a tap on one explains it and
/// offers Delete (with Undo) instead of doing nothing.
Future<void> showAdjustmentDetails(
  BuildContext context,
  WidgetRef ref,
  TransactionModel adjustment,
) async {
  final delete = await showDialog<bool>(
    context: context,
    builder: (_) => AdjustmentDetailsDialog(adjustment: adjustment),
  );
  if ((delete ?? false) && context.mounted) {
    await deleteTransactionWithUndo(context, ref, adjustment.id);
  }
}

class AdjustmentDetailsDialog extends ConsumerWidget {
  const AdjustmentDetailsDialog({required this.adjustment, super.key});

  final TransactionModel adjustment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final added = adjustment.isIncome;
    final date = DateTimeUtils.parseTransactionDate(adjustment.date);
    final time = DateTimeUtils.timeOfTimestamp(adjustment.timestamp);
    final when = [
      if (date != null) DateTimeUtils.displayDate(date) else adjustment.date,
      if (time != null) time,
    ].join(' · ');
    final note = adjustment.note?.trim() ?? '';

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: const Text(
                'Balance adjustment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ZenioColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: ZenioSpacing.lg),
            Text(
              Money.signed(
                adjustment.amount,
                symbol: ref.watch(currencySymbolProvider),
                direction:
                    added ? MoneyDirection.incoming : MoneyDirection.outgoing,
              ),
              style: AppFonts.numeric(
                fontSize: ZenioFontSizes.amount,
                fontWeight: FontWeight.bold,
                color: ZenioColors.textPrimary,
              ),
            ),
            const SizedBox(height: ZenioSpacing.xs),
            Text(
              '${added ? 'Added to' : 'Taken from'} '
              '${adjustment.bankName ?? 'a wallet'}',
              style: const TextStyle(
                fontSize: ZenioFontSizes.body,
                color: ZenioColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              when,
              style: const TextStyle(
                fontSize: ZenioFontSizes.label,
                color: ZenioColors.textSecondary,
              ),
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: ZenioSpacing.md),
              Text(
                note,
                style: const TextStyle(
                  fontSize: ZenioFontSizes.body,
                  color: ZenioColors.textPrimary,
                ),
              ),
            ],
            const SizedBox(height: ZenioSpacing.lg),
            const Text(
              "An adjustment corrects a wallet's balance. It isn't income or "
              "spending, and it can't be edited: to change it, delete it "
              'and adjust the wallet again.',
              style: TextStyle(
                fontSize: ZenioFontSizes.label,
                color: ZenioColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: ZenioSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: ZenioColors.danger,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Delete'),
                ),
                const SizedBox(width: ZenioSpacing.xs),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: ZenioColors.textPrimary,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
