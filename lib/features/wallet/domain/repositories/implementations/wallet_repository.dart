import 'package:zenio/shared/providers/providers.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/repositories/interfaces/i_wallet_repository.dart';

part 'wallet_repository.g.dart';

class WalletRepository implements IWalletRepository {
  WalletRepository(this._prefs);

  final SqlitePrefs _prefs;

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

    return [];
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
  final prefsAsync = ref.watch(sqlitePrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  if (prefs == null) {
    throw Exception('SqlitePrefs not initialized yet');
  }
  return WalletRepository(prefs);
}
