import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/shared/utils/currency_display.dart';

void main() {
  test('US dollars, stored as DLR, are shown as USD', () {
    expect(currencyDisplayCode('DLR'), 'USD');
    expect(currencyDisplayCode('dlr'), 'USD');
    expect(currencyDisplayCode('INR'), 'INR');
  });
}
