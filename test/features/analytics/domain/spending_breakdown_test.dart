import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/features/analytics/domain/spending_breakdown.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';

CategorySpendModel _spend(String name, double amount) => CategorySpendModel(
      id: name,
      name: name,
      amount: amount,
      spendsCount: 1,
      colorHex: '',
      iconName: '',
    );

TransactionModel _tx(String title, double amount, {String kind = 'expense'}) =>
    TransactionModel(
      id: '$title$amount',
      title: title,
      date: '15-09-2026',
      amount: amount,
      currency: 'INR',
      isIncome: kind == 'income',
      bankName: 'HDFC',
      kind: kind,
    );

void main() {
  test('the chart adds everything past the ninth category up as Other', () {
    final spends = [for (var i = 12; i > 0; i--) _spend('C$i', i * 10)];

    final slices = withOtherSlice(spends);

    expect(slices, hasLength(10));
    expect(slices.last.name, 'Other');
    expect(slices.last.amount, 30 + 20 + 10);
    expect(slices.last.spendsCount, 3);
    final total = spends.fold<double>(0, (sum, s) => sum + s.amount);
    expect(slices.fold<double>(0, (sum, s) => sum + s.amount), total);
  });

  test('up to ten categories are shown as they are', () {
    final spends = [_spend('Food', 50), _spend('Bills', 20)];

    expect(withOtherSlice(spends), same(spends));
  });

  test('spending under a title that is no longer a category is kept', () {
    final transactions = [
      _tx('Food', 100),
      _tx('Dining', 40), // "Food" was renamed; older ones say "Dining".
      _tx('Salary', 900, kind: 'income'),
      _tx(' food ', 5),
    ];

    final left = uncategorisedExpenses(transactions, ['Food', 'Bills']);

    expect(left.map((t) => t.title), ['Dining']);
  });
}
