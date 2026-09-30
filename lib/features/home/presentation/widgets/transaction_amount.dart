import 'package:flutter/material.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/widgets/money.dart';

/// How a transaction moves money: income in, spending out, transfers
/// neither. An adjustment goes whichever way it changed the balance.
MoneyDirection moneyDirectionOf(TransactionKind kind, {required bool isIncome}) {
  return switch (kind) {
    TransactionKind.income => MoneyDirection.incoming,
    TransactionKind.expense => MoneyDirection.outgoing,
    TransactionKind.transfer => MoneyDirection.neutral,
    TransactionKind.adjustment =>
      isIncome ? MoneyDirection.incoming : MoneyDirection.outgoing,
  };
}

/// Adjustments are neither income nor spending, so they are never shown in
/// the income colour.
Color? amountColorOf(TransactionKind kind) =>
    kind == TransactionKind.adjustment ? ZenioColors.textPrimary : null;

/// What a screen reader says for a transaction row, for example
/// "Expense, Food, −₹420, Today".
String transactionSemanticsLabel({
  required TransactionKind kind,
  required String title,
  required String amount,
  required String when,
}) {
  final type = switch (kind) {
    TransactionKind.income => 'Income',
    TransactionKind.expense => 'Expense',
    TransactionKind.transfer => 'Transfer',
    TransactionKind.adjustment => 'Balance adjustment',
  };
  // A title that already says what it is ("Balance adjustment") is not
  // repeated.
  final parts = [
    type,
    if (title.trim().toLowerCase() != type.toLowerCase()) title,
    amount,
    when,
  ];
  return parts.join(', ');
}
