import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';

/// What a transaction does with money.
///
/// Stored in the `kind` column. Rows saved before that column existed have no
/// kind; they are inferred from their title and wallet, exactly as the app
/// always did (see [resolveTransactionKind]).
enum TransactionKind {
  expense,
  income,

  /// Moves money between two of the user's wallets.
  transfer,

  /// A manual correction of a wallet balance. Changes the balance but is
  /// neither income nor spending.
  adjustment,
}

/// Separates the source and destination wallet of a transfer in `bank_name`.
const String transferWalletSeparator = ' -> ';

/// Title given to new transfers, followed by the destination wallet.
const String transferTitlePrefix = 'Transfer to ';

/// Title given to balance adjustments.
const String balanceAdjustmentTitle = 'Balance adjustment';

TransactionKind resolveTransactionKind({
  required String? kind,
  required String title,
  required String? bankName,
  required bool isIncome,
}) {
  final stored = kind == null ? null : TransactionKind.values.asNameMap()[kind];
  if (stored != null) return stored;
  if (title.startsWith(transferTitlePrefix.trim()) ||
      (bankName?.contains('->') ?? false)) {
    return TransactionKind.transfer;
  }
  return isIncome ? TransactionKind.income : TransactionKind.expense;
}

/// The source and destination wallet names of a transfer stored as
/// "Source -> Destination", or null when [bankName] is not in that form.
({String from, String to})? parseTransferWallets(String? bankName) {
  if (bankName == null) return null;
  final index = bankName.indexOf('->');
  if (index == -1) return null;
  return (
    from: bankName.substring(0, index).trim(),
    to: bankName.substring(index + 2).trim(),
  );
}

extension TransactionModelKind on TransactionModel {
  TransactionKind get resolvedKind => resolveTransactionKind(
        kind: kind,
        title: title,
        bankName: bankName,
        isIncome: isIncome,
      );

  /// Whether this counts towards income and spending totals. Transfers and
  /// balance adjustments only move or correct money.
  bool get countsAsIncomeOrExpense =>
      resolvedKind == TransactionKind.income ||
      resolvedKind == TransactionKind.expense;
}

extension TransactionDetailModelKind on TransactionDetailModel {
  TransactionKind get resolvedKind => resolveTransactionKind(
        kind: kind,
        title: title,
        bankName: bankName,
        isIncome: isIncome,
      );

  bool get countsAsIncomeOrExpense =>
      resolvedKind == TransactionKind.income ||
      resolvedKind == TransactionKind.expense;
}
