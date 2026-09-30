import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/wallet_kind.dart';

WalletCardModel _wallet(String type, [String number = '']) => WalletCardModel(
      id: '1',
      bankName: 'Wallet',
      cardNumber: number,
      cardType: type,
      gradientStartHex: '0xFF000000',
      gradientEndHex: '0xFF111111',
    );

void main() {
  group('credit', () {
    test('is the Credit preset, however it was written', () {
      for (final type in ['CREDIT CARD', 'Credit Card', ' credit card ']) {
        expect(_wallet(type).isCredit, isTrue, reason: type);
      }
      // The short form the wallet forms already take for the preset.
      expect(_wallet('CREDIT').isCredit, isTrue);
    });

    test('is not a type the user named with "credit" in it', () {
      for (final type in [
        'Credit union savings',
        'Store credit',
        'Business Platinum Credit Card',
        'DEBIT CARD',
        'CASH',
        'SAVINGS',
        'BANK',
      ]) {
        expect(_wallet(type).isCredit, isFalse, reason: type);
      }
    });
  });

  group('card numbers', () {
    test('numbers Zenio made up are recognised', () {
      expect(isGeneratedWalletNumber('4821  1093  7702  5518'), isTrue);
      expect(isGeneratedWalletNumber('9999  1000  5555  1234'), isTrue);
      expect(isGeneratedWalletNumber('**** **** **** 5518'), isTrue);
    });

    test('numbers a user could have entered are not', () {
      for (final number in [
        '4111111111111234', // digits, as the number field takes them
        '1234',
        '4821 1093 7702 5518', // one space: not the generated shape
        '0123  4567  8901  2345', // a group the generator never made
        '4821  1093  7702  551',
        '',
      ]) {
        expect(isGeneratedWalletNumber(number), isFalse, reason: number);
      }
    });

    test('a made-up number is never shown as the last four', () {
      expect(_wallet('CREDIT CARD', '4821  1093  7702  5518').lastFour, isNull);
      expect(_wallet('DEBIT CARD', '**** **** **** 5518').lastFour, isNull);
    });

    test('digits the user entered are', () {
      expect(_wallet('CREDIT CARD', '4111111111111234').lastFour, '1234');
      expect(_wallet('DEBIT CARD', '5678').lastFour, '5678');
      expect(_wallet('DEBIT CARD', '4821 1093 7702 5518').lastFour, '5518');
    });

    test('a wallet that is not a card shows none', () {
      expect(_wallet('CASH', '4111111111111234').lastFour, isNull);
    });
  });
}
