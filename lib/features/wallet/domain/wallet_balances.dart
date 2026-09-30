import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';

/// A wallet's balance is its opening balance plus the effect of every
/// transaction recorded against it.
///
/// Transactions name their wallet instead of referencing its id, so a name is
/// attributed to the first wallet with that name (ignoring case and outer
/// spaces). That is how balances were always updated, so migrated balances
/// match what users saw before. Transactions naming no current wallet (for
/// example of a deleted wallet) affect no balance.
Map<String, double> walletTransactionTotals(
  List<WalletCardModel> wallets,
  Iterable<TransactionModel> transactions,
) {
  final idByName = <String, String>{};
  for (final wallet in wallets) {
    idByName.putIfAbsent(walletNameKey(wallet.bankName), () => wallet.id);
  }
  final totals = {for (final wallet in wallets) wallet.id: 0.0};

  void apply(String? walletName, double delta) {
    if (walletName == null) return;
    final id = idByName[walletNameKey(walletName)];
    if (id != null) totals[id] = totals[id]! + delta;
  }

  for (final tx in transactions) {
    switch (tx.resolvedKind) {
      case TransactionKind.transfer:
        final ends = parseTransferWallets(tx.bankName);
        if (ends != null) {
          apply(ends.from, -tx.amount);
          apply(ends.to, tx.amount);
        }
      case TransactionKind.income:
        apply(tx.bankName, tx.amount);
      case TransactionKind.expense:
        apply(tx.bankName, -tx.amount);
      case TransactionKind.adjustment:
        apply(tx.bankName, tx.isIncome ? tx.amount : -tx.amount);
    }
  }
  return totals;
}

/// Gives every wallet without an opening balance the one that makes its
/// derived balance equal to the balance it shows now, so migrating never
/// changes a number the user sees. Wallets that have one are unchanged.
List<WalletCardModel> withOpeningBalances(
  List<WalletCardModel> wallets,
  Iterable<TransactionModel> transactions,
) {
  final totals = walletTransactionTotals(wallets, transactions);
  return [
    for (final wallet in wallets)
      wallet.openingBalance != null
          ? wallet
          : wallet.copyWith(
              openingBalance: roundToCents(wallet.balance - totals[wallet.id]!),
            ),
  ];
}

/// Sets the opening balance of every wallet listed in [shown] (and already
/// migrated) so that, with [transactions], it shows exactly that balance.
List<WalletCardModel> keepShownBalances(
  List<WalletCardModel> wallets,
  Iterable<TransactionModel> transactions,
  Map<String, double> shown,
) {
  final totals = walletTransactionTotals(wallets, transactions);
  return [
    for (final wallet in wallets)
      if (wallet.openingBalance != null && shown.containsKey(wallet.id))
        wallet.copyWith(
          openingBalance: roundToCents(shown[wallet.id]! - totals[wallet.id]!),
        )
      else
        wallet,
  ];
}

/// Recomputes each wallet's balance from its opening balance and
/// [transactions]. Wallets without an opening balance keep their stored one.
List<WalletCardModel> withDerivedBalances(
  List<WalletCardModel> wallets,
  Iterable<TransactionModel> transactions,
) {
  final totals = walletTransactionTotals(wallets, transactions);
  return [
    for (final wallet in wallets)
      wallet.openingBalance == null
          ? wallet
          : wallet.copyWith(
              balance:
                  roundToCents(wallet.openingBalance! + totals[wallet.id]!),
            ),
  ];
}

/// The key wallet names are compared by.
String walletNameKey(String name) => name.trim().toLowerCase();

double roundToCents(double amount) => (amount * 100).roundToDouble() / 100;

/// The title and wallet of a transaction after the wallet [oldName] was
/// renamed to [newName], or null when the transaction does not refer to it.
({String title, String? bankName})? renamedWalletReferences({
  required String title,
  required String? bankName,
  required String oldName,
  required String newName,
}) {
  final old = walletNameKey(oldName);
  bool isOld(String name) => walletNameKey(name) == old;

  final ends = parseTransferWallets(bankName);
  if (ends != null) {
    final from = isOld(ends.from) ? newName : ends.from;
    final to = isOld(ends.to) ? newName : ends.to;
    if (from == ends.from && to == ends.to) return null;
    const prefix = transferTitlePrefix;
    final renamedTitle =
        title.startsWith(prefix) && isOld(title.substring(prefix.length))
            ? '$prefix$newName'
            : title;
    return (
      title: renamedTitle,
      bankName: '$from$transferWalletSeparator$to',
    );
  }

  if (bankName != null && isOld(bankName)) {
    return (title: title, bankName: newName);
  }
  return null;
}

/// [transactions] after the wallet [oldName] was renamed to [newName], as
/// the database stores them after renaming.
List<TransactionModel> withWalletRenamed(
  List<TransactionModel> transactions,
  String oldName,
  String newName,
) {
  return [
    for (final tx in transactions)
      switch (renamedWalletReferences(
        title: tx.title,
        bankName: tx.bankName,
        oldName: oldName,
        newName: newName,
      )) {
        null => tx,
        final renamed =>
          tx.copyWith(title: renamed.title, bankName: renamed.bankName),
      },
  ];
}
