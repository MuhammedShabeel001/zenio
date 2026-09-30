import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';

abstract class IWalletRepository {
  Future<List<WalletCardModel>> getCards();
  Future<void> saveCards(List<WalletCardModel> cards);

  /// Saves [cards] and inserts [transactions] in one database transaction:
  /// either both are stored or neither is. Fails, storing nothing, if any
  /// transaction already exists or its amount is not storable.
  Future<void> saveCardsWithTransactions(
    List<WalletCardModel> cards,
    List<TransactionModel> transactions,
  );

  /// Keeps a copy of the stored wallets, exactly as saved, before they are
  /// first migrated. Only the first call writes anything.
  Future<void> backupCardsBeforeMigration();

  /// Clears the card numbers Zenio made up when wallets were added (see
  /// `isGeneratedWalletNumber`) from the stored wallets and from the copy
  /// kept by [backupCardsBeforeMigration], and returns how many it cleared.
  /// Nothing else changes, and with none left it writes nothing.
  Future<int> clearGeneratedCardNumbers();
}
