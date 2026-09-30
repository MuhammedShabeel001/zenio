import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/shared/widgets/money.dart';

void main() {
  test('amounts carry their direction in the sign, with two decimals', () {
    expect(
      Money.signed(85000, symbol: '₹', direction: MoneyDirection.incoming),
      '+₹85,000.00',
    );
    expect(
      Money.signed(420, symbol: '₹', direction: MoneyDirection.outgoing),
      '−₹420.00',
    );
    expect(
      Money.signed(2000.5, symbol: r'$', direction: MoneyDirection.neutral),
      r'$2,000.50',
    );
  });

  test('nothing that shows as zero gets a sign', () {
    expect(
      Money.signed(0.001, symbol: '₹', direction: MoneyDirection.outgoing),
      '₹0.00',
    );
    expect(Money.balance(-0.004, symbol: '₹'), '₹0.00');
    const negativeZero = -0.1 * 0;
    expect(Money.balance(negativeZero, symbol: '₹'), '₹0.00');
  });

  test('a balance below zero is written with a minus before the symbol', () {
    expect(Money.balance(-2450, symbol: '₹'), '−₹2,450.00');
    expect(Money.balance(2450, symbol: '₹'), '₹2,450.00');
    // Never "₹ -2,450" or a hyphen.
    expect(Money.balance(-2450, symbol: '₹'), isNot(contains('-')));
  });

  test('a value that is not a number never breaks a screen', () {
    expect(Money.balance(double.infinity, symbol: '₹'), '₹—');
    expect(
      Money.signed(double.nan, symbol: '₹', direction: MoneyDirection.outgoing),
      '₹—',
    );
  });
}
