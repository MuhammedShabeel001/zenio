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

/// How a transfer between [from] and [to] reads in `bank_name`, which is
/// shown and exported: "From -> To".
String transferBankName(String from, String to) =>
    '$from$transferWalletSeparator$to';

/// The source and destination wallet of a transfer.
///
/// Transfers keep them in their own fields ([transferFrom], [transferTo]),
/// so a wallet whose name contains "->" is never split apart. Transfers
/// saved before those fields existed only have [bankName] ("Source ->
/// Destination"). It is read as it always was, at its first "->", unless it
/// holds more than one and [title] ("Transfer to X") names the destination
/// of exactly one of the ways to split it. Null when neither is available.
({String from, String to})? transferWallets({
  required String? transferFrom,
  required String? transferTo,
  required String? bankName,
  required String title,
}) {
  if (transferFrom != null && transferTo != null) {
    return (from: transferFrom, to: transferTo);
  }
  final splits = transferSplits(bankName);
  if (splits.isEmpty) return null;
  if (splits.length > 1 && title.startsWith(transferTitlePrefix)) {
    final destination =
        title.substring(transferTitlePrefix.length).trim().toLowerCase();
    final matching =
        splits.where((split) => split.to.toLowerCase() == destination);
    if (matching.length == 1) return matching.single;
  }
  return splits.first;
}

/// Every way [text] splits into a source and a destination at a "->", in
/// order. Empty when it has none.
List<({String from, String to})> transferSplits(String? text) {
  if (text == null) return const [];
  final splits = <({String from, String to})>[];
  var index = text.indexOf('->');
  while (index != -1) {
    splits.add(
      (
        from: text.substring(0, index).trim(),
        to: text.substring(index + 2).trim(),
      ),
    );
    index = text.indexOf('->', index + 2);
  }
  return splits;
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

  /// The source and destination wallet when this is a transfer; null for
  /// every other kind, whatever its wallet is called.
  ({String from, String to})? get transferEnds =>
      resolvedKind == TransactionKind.transfer
          ? transferWallets(
              transferFrom: transferFrom,
              transferTo: transferTo,
              bankName: bankName,
              title: title,
            )
          : null;
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

  /// See [TransactionModelKind.transferEnds].
  ({String from, String to})? get transferEnds =>
      resolvedKind == TransactionKind.transfer
          ? transferWallets(
              transferFrom: transferFrom,
              transferTo: transferTo,
              bankName: bankName,
              title: title,
            )
          : null;
}

extension TransactionDetailModelConversion on TransactionDetailModel {
  /// The same transaction as the model the rest of the app uses.
  TransactionModel toModel() => TransactionModel(
        id: id,
        title: title,
        date: date,
        amount: amount,
        isIncome: isIncome,
        currency: currency,
        note: note,
        bankName: bankName,
        timestamp: timestamp,
        kind: kind,
        transferFrom: transferFrom,
        transferTo: transferTo,
      );
}
