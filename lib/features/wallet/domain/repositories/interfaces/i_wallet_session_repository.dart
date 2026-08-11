import 'package:zenio/features/wallet/domain/models/wallet_session_model.dart';

abstract class IWalletSessionRepository {
  Future<List<WalletSessionModel>> getWalletSessions();
  Future<WalletSessionModel?> getWalletSessionById(String walletId);
  Future<void> saveWalletSession(WalletSessionModel wallet);
  Future<void> updateWalletSession(WalletSessionModel wallet);
  Future<void> deleteWalletSession(String walletId);
  Future<void> toggleFreezeWalletSession(String walletId);
  Future<void> clearAllWalletSessions();
  String generate16DigitWalletId();
}
