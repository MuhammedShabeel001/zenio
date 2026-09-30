import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/repositories/interfaces/i_wallet_repository.dart';
import 'package:zenio/shared/providers/providers.dart';

part 'wallet_repository.g.dart';

class WalletRepository implements IWalletRepository {
  WalletRepository(this._prefs);

  final SqlitePrefs _prefs;

  static const String _cardsKey = 'wallet_cards_list';
  static const String _preMigrationBackupKey =
      'wallet_cards_list.before_opening_balances';

  @override
  Future<List<WalletCardModel>> getCards() {
    return _prefs.readJsonList(_cardsKey, WalletCardModel.fromJson);
  }

  @override
  Future<void> backupCardsBeforeMigration() async {
    final raw = _prefs.getString(_cardsKey);
    if (raw == null || _prefs.containsKey(_preMigrationBackupKey)) return;
    await _prefs.setString(_preMigrationBackupKey, raw);
  }

  @override
  Future<void> saveCards(List<WalletCardModel> cards) async {
    final jsonList = cards.map((card) => jsonEncode(card.toJson())).toList();
    await _prefs.setStringList(_cardsKey, jsonList);
  }
}

@Riverpod(keepAlive: true)
IWalletRepository walletRepositoryRepo(Ref ref) {
  final prefs = ref.watch(sqlitePrefsProvider).valueOrNull;
  if (prefs == null) {
    throw StateError('Local storage is not ready yet.');
  }
  return WalletRepository(prefs);
}
