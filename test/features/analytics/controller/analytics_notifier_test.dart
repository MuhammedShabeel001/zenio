import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/analytics/controller/analytics/analytics_notifier.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';

class _FakeHomeNotifier extends HomeNotifier {
  _FakeHomeNotifier(this._initialTransactions);

  final List<TransactionModel> _initialTransactions;

  @override
  HomeState build() {
    return HomeState(
      status: HomeStatus.success,
      transactions: _initialTransactions,
    );
  }
}

class _FakeWalletNotifier extends WalletNotifier {
  _FakeWalletNotifier(this._initialCards);

  final List<WalletCardModel> _initialCards;

  @override
  WalletState build() {
    return WalletState(
      status: WalletStatus.success,
      cards: _initialCards,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final currentDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

  final sampleTransactions = [
    TransactionModel(
      id: 'tx-1',
      title: 'Food & Drink',
      date: currentDate,
      amount: 150.0,
      currency: 'INR',
      isIncome: false,
      bankName: 'HDFC Bank',
    ),
    TransactionModel(
      id: 'tx-2',
      title: 'Shopping',
      date: currentDate,
      amount: 350.0,
      currency: 'INR',
      isIncome: false,
      bankName: 'HDFC Bank',
    ),
    TransactionModel(
      id: 'tx-3',
      title: 'Travel',
      date: currentDate,
      amount: 500.0,
      currency: 'INR',
      isIncome: false,
      bankName: 'Chase Bank',
    ),
    TransactionModel(
      id: 'tx-4',
      title: 'Salary',
      date: currentDate,
      amount: 5000.0,
      currency: 'INR',
      isIncome: true,
      bankName: 'Chase Bank',
    ),
  ];

  final sampleCards = [
    const WalletCardModel(
      id: 'card-1',
      bankName: 'HDFC Bank',
      cardNumber: '1111',
      cardType: 'VISA',
      gradientStartHex: '0xFF000000',
      gradientEndHex: '0xFF111111',
    ),
    const WalletCardModel(
      id: 'card-2',
      bankName: 'Chase Bank',
      cardNumber: '2222',
      cardType: 'MASTERCARD',
      gradientStartHex: '0xFF222222',
      gradientEndHex: '0xFF333333',
    ),
  ];

  group('AnalyticsNotifier Wallet Filtering', () {
    test('computes total balance and category spends for All Wallets', () {
      final container = ProviderContainer(
        overrides: [
          homeNotifierProvider.overrideWith(
            () => _FakeHomeNotifier(sampleTransactions),
          ),
          walletNotifierProvider.overrideWith(
            () => _FakeWalletNotifier(sampleCards),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(analyticsNotifierProvider);

      expect(state.selectedWallet, 'All Wallets');
      // Total expense across all wallets: 150 + 350 + 500 = 1000
      expect(state.totalBalance, 1000.0);
      expect(state.categorySpends.length, 3);
    });

    test('filters spends when a specific wallet is selected', () {
      final container = ProviderContainer(
        overrides: [
          homeNotifierProvider.overrideWith(
            () => _FakeHomeNotifier(sampleTransactions),
          ),
          walletNotifierProvider.overrideWith(
            () => _FakeWalletNotifier(sampleCards),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(analyticsNotifierProvider.notifier);

      // Select HDFC Bank
      notifier.updateWallet('HDFC Bank');
      var state = container.read(analyticsNotifierProvider);

      expect(state.selectedWallet, 'HDFC Bank');
      // HDFC only: 150 (Food & Drink) + 350 (Shopping) = 500
      expect(state.totalBalance, 500.0);
      expect(state.categorySpends.length, 2);
      expect(state.categorySpends.map((s) => s.name), containsAll(['Food & Drink', 'Shopping']));

      // Select Chase Bank
      notifier.updateWallet('Chase Bank');
      state = container.read(analyticsNotifierProvider);

      expect(state.selectedWallet, 'Chase Bank');
      // Chase only: 500 (Travel), salary is income so ignored
      expect(state.totalBalance, 500.0);
      expect(state.categorySpends.length, 1);
      expect(state.categorySpends.first.name, 'Travel');

      // Switch back to All Wallets
      notifier.updateWallet('All Wallets');
      state = container.read(analyticsNotifierProvider);

      expect(state.selectedWallet, 'All Wallets');
      expect(state.totalBalance, 1000.0);
      expect(state.categorySpends.length, 3);
    });

    test('filterTransactions returns wallet-filtered transactions list', () {
      final container = ProviderContainer(
        overrides: [
          homeNotifierProvider.overrideWith(
            () => _FakeHomeNotifier(sampleTransactions),
          ),
          walletNotifierProvider.overrideWith(
            () => _FakeWalletNotifier(sampleCards),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(analyticsNotifierProvider.notifier);

      notifier.updateWallet('HDFC Bank');
      final filtered = notifier.filterTransactions(sampleTransactions);

      expect(filtered.every((tx) => tx.bankName == 'HDFC Bank'), isTrue);
      expect(filtered.length, 2);
    });

    test('correctly parses dates in long format like EEEE, MMMM d, yyyy (client bug scenario)', () {
      final now = DateTime.now();
      final longFormattedDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
      final standardDate = DateFormat('dd-MM-yyyy').format(now);

      final mixedTransactions = [
        TransactionModel(
          id: 'tx-grocery',
          title: 'Grocery',
          date: longFormattedDate,
          amount: 267.0,
          currency: 'INR',
          isIncome: false,
          bankName: 'Main wallet',
        ),
        TransactionModel(
          id: 'tx-other',
          title: 'Other',
          date: standardDate,
          amount: 3.0,
          currency: 'INR',
          isIncome: false,
          bankName: 'Main wallet',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          homeNotifierProvider.overrideWith(
            () => _FakeHomeNotifier(mixedTransactions),
          ),
          walletNotifierProvider.overrideWith(
            () => _FakeWalletNotifier([
              const WalletCardModel(
                id: 'card-main',
                bankName: 'Main wallet',
                cardNumber: '9999',
                cardType: 'VISA',
                gradientStartHex: '0xFF000000',
                gradientEndHex: '0xFF111111',
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(analyticsNotifierProvider);

      // Both transactions should be included now
      expect(state.totalBalance, 270.0);
      expect(state.categorySpends.any((c) => c.name == 'Grocery' && c.amount == 267.0), isTrue);
      expect(state.categorySpends.any((c) => c.name == 'Other' && c.amount == 3.0), isTrue);
    });
  });
}
