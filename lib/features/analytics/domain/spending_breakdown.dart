import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';

/// [spends] (largest first) as at most [slices] parts: the largest ones and
/// a last "Other" part for the rest, so together they are all the spending.
List<CategorySpendModel> withOtherSlice(
  List<CategorySpendModel> spends, {
  int slices = 10,
}) {
  if (spends.length <= slices) return spends;
  final rest = spends.skip(slices - 1);
  return [
    ...spends.take(slices - 1),
    CategorySpendModel(
      id: '_other',
      name: 'Other',
      amount: rest.fold<double>(0, (sum, c) => sum + c.amount),
      spendsCount: rest.fold<int>(0, (sum, c) => sum + c.spendsCount),
      colorHex: '0xFF9E9EA5',
      iconName: '',
    ),
  ];
}

/// Spending filed under a title that is not (or no longer) one of
/// [categoryNames], for example after renaming a category or importing a
/// file. Compared ignoring case and outer spaces.
List<TransactionModel> uncategorisedExpenses(
  Iterable<TransactionModel> transactions,
  Iterable<String> categoryNames,
) {
  final names = {for (final name in categoryNames) name.trim().toLowerCase()};
  return [
    for (final tx in transactions)
      if (tx.resolvedKind == TransactionKind.expense &&
          !names.contains(tx.title.trim().toLowerCase()))
        tx,
  ];
}
