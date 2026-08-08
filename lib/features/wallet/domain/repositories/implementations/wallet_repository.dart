import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/repositories/interfaces/i_wallet_repository.dart';
import 'package:zenio/shared/providers/shared_prefs_provider/shared_prefs_provider.dart';

part 'wallet_repository.g.dart';

class WalletRepository implements IWalletRepository {
  WalletRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _balanceKey = 'wallet_card_balance';
  static const String _cardsKey = 'wallet_cards_list';

  @override
  Future<double> getCardBalance() async {
    final balance = _prefs.getDouble(_balanceKey);
    if (balance != null) {
      return balance;
    }
    const defaultBalance = 2678.01;
    await saveCardBalance(defaultBalance);
    return defaultBalance;
  }

  @override
  Future<List<WalletCardModel>> getCards() async {
    final rawJsonList = _prefs.getStringList(_cardsKey);
    if (rawJsonList != null && rawJsonList.isNotEmpty) {
      try {
        return rawJsonList.map((item) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          return WalletCardModel.fromJson(map);
        }).toList();
      } catch (_) {
        // Fallback to defaults
      }
    }

    final defaultCards = [
      const WalletCardModel(
        id: '1',
        bankName: 'SBI',
        cardNumber: '****  ****  ****  ****',
        cardType: 'DEBIT CARD',
        gradientStartHex: '0xFF031B4E',
        gradientEndHex: '0xFF1B59C9',
      ),
      const WalletCardModel(
        id: '2',
        bankName: 'HDFC',
        cardNumber: '****  ****  ****  ****',
        cardType: 'CREDIT CARD',
        gradientStartHex: '0xFF881B5A',
        gradientEndHex: '0xFFD81B60',
      ),
      const WalletCardModel(
        id: '3',
        bankName: 'ICICI',
        cardNumber: '****  ****  ****  ****',
        cardType: 'DEBIT CARD',
        gradientStartHex: '0xFF1B4D2E',
        gradientEndHex: '0xFF2E7D32',
      ),
      const WalletCardModel(
        id: '4',
        bankName: 'AXIS',
        cardNumber: '****  ****  ****  ****',
        cardType: 'CREDIT CARD',
        gradientStartHex: '0xFF4A148C',
        gradientEndHex: '0xFF7B1FA2',
      ),
      const WalletCardModel(
        id: '5',
        bankName: 'KOTAK',
        cardNumber: '****  ****  ****  ****',
        cardType: 'DEBIT CARD',
        gradientStartHex: '0xFFB71C1C',
        gradientEndHex: '0xFFE53935',
      ),
    ];
    await saveCards(defaultCards);
    return defaultCards;
  }

  @override
  Future<void> saveCardBalance(double balance) async {
    await _prefs.setDouble(_balanceKey, balance);
  }

  @override
  Future<void> saveCards(List<WalletCardModel> cards) async {
    final jsonList = cards.map((card) => jsonEncode(card.toJson())).toList();
    await _prefs.setStringList(_cardsKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
IWalletRepository walletRepositoryRepo(Ref ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized yet');
  }
  return WalletRepository(prefs);
}
