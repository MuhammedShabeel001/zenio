import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/wallet_balances.dart';

WalletCardModel _wallet(
  String id,
  String name, {
  double balance = 0,
  double? opening,
}) =>
    WalletCardModel(
      id: id,
      bankName: name,
      cardNumber: '0000',
      cardType: 'Debit Card',
      gradientStartHex: '',
      gradientEndHex: '',
      balance: balance,
      openingBalance: opening,
    );

TransactionModel _tx(
  String bankName,
  double amount, {
  bool isIncome = false,
  String title = 'Food',
  String? kind,
}) =>
    TransactionModel(
      id: '$bankName$amount$title',
      title: title,
      date: '01-09-2026',
      amount: amount,
      currency: 'INR',
      isIncome: isIncome,
      bankName: bankName,
      kind: kind,
    );

void main() {
  group('walletTransactionTotals', () {
    test('adds income, subtracts spending, moves transfers', () {
      final wallets = [_wallet('1', 'HDFC'), _wallet('2', 'Cash')];
      final totals = walletTransactionTotals(wallets, [
        _tx('HDFC', 100),
        _tx('hdfc ', 40, isIncome: true),
        _tx('HDFC -> Cash', 30, title: 'Transfer to Cash'),
      ]);

      expect(totals, {'1': -90.0, '2': 30.0});
    });

    test('applies adjustments in their direction', () {
      final wallets = [_wallet('1', 'HDFC')];
      final totals = walletTransactionTotals(wallets, [
        _tx('HDFC', 50, isIncome: true, kind: 'adjustment'),
        _tx('HDFC', 20, kind: 'adjustment'),
      ]);

      expect(totals['1'], 30);
    });

    test('attributes a shared name to the first wallet only', () {
      final wallets = [_wallet('1', 'HDFC'), _wallet('2', 'HDFC')];
      final totals = walletTransactionTotals(wallets, [_tx('HDFC', 10)]);

      expect(totals, {'1': -10.0, '2': 0.0});
    });

    test('ignores transactions of wallets that no longer exist', () {
      final totals = walletTransactionTotals(
        [_wallet('1', 'HDFC')],
        [_tx('Old bank', 999)],
      );

      expect(totals['1'], 0);
    });
  });

  group('migration to opening balances', () {
    test('keeps every visible balance unchanged', () {
      final wallets = [
        _wallet('1', 'HDFC', balance: 500),
        _wallet('2', 'Cash', balance: 120.55),
      ];
      final transactions = [
        _tx('HDFC', 200),
        _tx('HDFC', 1000, isIncome: true),
        _tx('HDFC -> Cash', 75.5, title: 'Transfer to Cash'),
      ];

      final migrated = withOpeningBalances(wallets, transactions);
      final derived = withDerivedBalances(migrated, transactions);

      expect(migrated.map((w) => w.openingBalance), [-224.5, 45.05]);
      expect(derived.map((w) => w.balance), [500, 120.55]);
    });

    test('leaves wallets that already have an opening balance alone', () {
      final wallets = [_wallet('1', 'HDFC', balance: 999, opening: 10)];

      final migrated = withOpeningBalances(wallets, [_tx('HDFC', 5)]);

      expect(migrated.single.openingBalance, 10);
    });

    test('derived balances follow later changes to the transactions', () {
      final migrated = withOpeningBalances(
        [_wallet('1', 'HDFC', balance: 500)],
        [_tx('HDFC', 200)],
      );

      // The 200 expense is deleted afterwards.
      final derived = withDerivedBalances(migrated, const []);

      expect(derived.single.balance, 700);
    });
  });

  group('renamedWalletReferences', () {
    test('renames a plain wallet reference', () {
      expect(
        renamedWalletReferences(
          kind: TransactionKind.expense,
          title: 'Food',
          bankName: 'hdfc',
          transferFrom: null,
          transferTo: null,
          oldName: 'HDFC',
          newName: 'HDFC Savings',
        ),
        (
          title: 'Food',
          bankName: 'HDFC Savings',
          transferFrom: null,
          transferTo: null,
        ),
      );
    });

    test('renames either end of a transfer and its title', () {
      expect(
        renamedWalletReferences(
          kind: TransactionKind.transfer,
          title: 'Transfer to Cash',
          bankName: 'HDFC -> Cash',
          transferFrom: null,
          transferTo: null,
          oldName: 'Cash',
          newName: 'Wallet',
        ),
        (
          title: 'Transfer to Wallet',
          bankName: 'HDFC -> Wallet',
          transferFrom: 'HDFC',
          transferTo: 'Wallet',
        ),
      );
      expect(
        renamedWalletReferences(
          kind: TransactionKind.transfer,
          title: 'Transfer to Cash',
          bankName: 'HDFC -> Cash',
          transferFrom: 'HDFC',
          transferTo: 'Cash',
          oldName: 'HDFC',
          newName: 'Bank',
        ),
        (
          title: 'Transfer to Cash',
          bankName: 'Bank -> Cash',
          transferFrom: 'Bank',
          transferTo: 'Cash',
        ),
      );
    });

    test('leaves unrelated transactions alone', () {
      expect(
        renamedWalletReferences(
          kind: TransactionKind.expense,
          title: 'Food',
          bankName: 'SBI',
          transferFrom: null,
          transferTo: null,
          oldName: 'HDFC',
          newName: 'Bank',
        ),
        isNull,
      );
    });
  });
}
