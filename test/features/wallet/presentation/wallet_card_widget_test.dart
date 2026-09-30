import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/presentation/widgets/wallet_card_widget.dart';

void main() {
  for (final textScale in [1.0, 1.3]) {
    testWidgets(
        'a card with long details fits a small phone at ${textScale}x text',
        (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      // A side card of the carousel on a 320pt wide screen.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 258,
                height: 175,
                child: WalletCardWidget(
                  isFrozen: true,
                  card: WalletCardModel(
                    id: '1',
                    bankName: 'State Bank of India Savings',
                    cardNumber: '4111111111111234',
                    cardType: 'Business Platinum Credit Card',
                    gradientStartHex: '0xFF000000',
                    gradientEndHex: '0xFF111111',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('**** **** **** 1234'), findsOneWidget);
    });
  }

  testWidgets('only a card shows digits, and only its last four',
      (tester) async {
    Future<void> show(String type, String number) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 200,
              child: WalletCardWidget(
                card: WalletCardModel(
                  id: '1',
                  bankName: 'Wallet',
                  cardNumber: number,
                  cardType: type,
                  gradientStartHex: '0xFF000000',
                  gradientEndHex: '0xFF111111',
                ),
              ),
            ),
          ),
        ),
      );
    }

    await show('CASH', '1234 5678 9012 3456');
    expect(find.textContaining('3456'), findsNothing);

    await show('DEBIT CARD', '1234 5678 9012 3456');
    expect(find.text('**** **** **** 3456'), findsOneWidget);
    expect(find.textContaining('1234 5678'), findsNothing);
  });
}
