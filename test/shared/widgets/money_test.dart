import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/shared/widgets/money.dart';

void main() {
  test('amounts carry their direction in the sign', () {
    expect(
      Money.signed(85000, symbol: '₹', direction: MoneyDirection.incoming),
      '+₹85,000',
    );
    expect(
      Money.signed(420, symbol: '₹', direction: MoneyDirection.outgoing),
      '−₹420',
    );
    expect(
      Money.signed(2000.5, symbol: r'$', direction: MoneyDirection.neutral),
      r'$2,000.50',
    );
  });

  test('nothing that shows as zero gets a sign', () {
    expect(
      Money.signed(0.001, symbol: '₹', direction: MoneyDirection.outgoing),
      '₹0',
    );
  });

  test('a balance below zero is written with a minus before the symbol', () {
    expect(Money.balance(-2450, symbol: '₹'), '−₹2,450');
    expect(Money.balance(2450, symbol: '₹'), '₹2,450');
  });
}
