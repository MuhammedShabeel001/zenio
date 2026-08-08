import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';

abstract class IWalletRepository {
  Future<double> getCardBalance();
  Future<List<WalletCardModel>> getCards();
  Future<void> saveCardBalance(double balance);
  Future<void> saveCards(List<WalletCardModel> cards);
}
