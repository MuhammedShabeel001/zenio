import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';

abstract class IWalletRepository {
  Future<List<WalletCardModel>> getCards();
  Future<void> saveCards(List<WalletCardModel> cards);

  /// Keeps a copy of the stored wallets, exactly as saved, before they are
  /// first migrated. Only the first call writes anything.
  Future<void> backupCardsBeforeMigration();
}
