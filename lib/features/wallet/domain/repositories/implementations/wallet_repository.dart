import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/home/domain/repositories/implementations/money_tracker/money_tracker_repository.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/repositories/interfaces/i_wallet_repository.dart';
import 'package:zenio/features/wallet/domain/wallet_kind.dart';
import 'package:zenio/shared/providers/providers.dart';
import 'package:zenio/shared/utils/money_limits.dart';

part 'wallet_repository.g.dart';

class WalletRepository implements IWalletRepository {
  WalletRepository(this._prefs);

  final SqlitePrefs _prefs;

  static const String _cardsKey = 'wallet_cards_list';
  static const String _preMigrationBackupKey =
      'wallet_cards_list.before_opening_balances';

  @override
  Future<List<WalletCardModel>> getCards() {
    return _prefs.readJsonList(_cardsKey, _decode);
  }

  /// A stored wallet whose balance is not a finite number is kept aside as
  /// unreadable (see [SqlitePrefs.readJsonList]) rather than shown.
  static WalletCardModel _decode(Map<String, dynamic> json) {
    final card = WalletCardModel.fromJson(json);
    _checkBalances(card);
    return card;
  }

  static void _checkBalances(WalletCardModel card) {
    final opening = card.openingBalance;
    if (!isStorableBalance(card.balance) ||
        (opening != null && !isStorableBalance(opening))) {
      throw const InvalidAmountException('wallet balance');
    }
  }

  @override
  Future<void> backupCardsBeforeMigration() async {
    final raw = _prefs.getString(_cardsKey);
    if (raw == null || _prefs.containsKey(_preMigrationBackupKey)) return;
    await _prefs.setString(_preMigrationBackupKey, raw);
  }

  /// Works on the wallets as stored, so every other wallet, field and
  /// unreadable entry stays exactly as it was; only a matching
  /// `card_number` becomes empty. The copy kept from before the move to
  /// opening balances holds the same numbers, so it is cleared the same way.
  @override
  Future<int> clearGeneratedCardNumbers() async {
    var cleared = 0;
    for (final key in const [_cardsKey, _preMigrationBackupKey]) {
      cleared += await _clearGeneratedCardNumbersIn(key);
    }
    return cleared;
  }

  /// Clears the made-up numbers of the wallets stored under [key], writing
  /// only when there is one. Returns how many were cleared.
  Future<int> _clearGeneratedCardNumbersIn(String key) async {
    final raw = _prefs.getString(key);
    if (raw == null) return 0;
    final List<dynamic> entries;
    try {
      entries = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      // Not a list; the normal read keeps it aside as unreadable.
      return 0;
    }
    var cleared = 0;
    for (var i = 0; i < entries.length; i++) {
      final cleaned = _withoutGeneratedNumber(entries[i]);
      if (cleaned != null) {
        entries[i] = cleaned;
        cleared++;
      }
    }
    if (cleared > 0) await _prefs.setString(key, jsonEncode(entries));
    return cleared;
  }

  /// [entry] (a stored wallet: a JSON string, or a map in older data) with
  /// its made-up card number cleared, in the same form; null when it has
  /// none or cannot be read.
  static Object? _withoutGeneratedNumber(Object? entry) {
    try {
      final json = entry is String ? jsonDecode(entry) : entry;
      if (json is! Map<String, dynamic>) return null;
      final number = json['card_number'];
      if (number is! String || !isGeneratedWalletNumber(number)) return null;
      final cleaned = {...json, 'card_number': ''};
      return entry is String ? jsonEncode(cleaned) : cleaned;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCards(List<WalletCardModel> cards) async {
    cards.forEach(_checkBalances);
    final jsonList = cards.map((card) => jsonEncode(card.toJson())).toList();
    await _prefs.setStringList(_cardsKey, jsonList);
  }

  @override
  Future<void> saveCardsWithTransactions(
    List<WalletCardModel> cards,
    List<TransactionModel> transactions,
  ) async {
    cards.forEach(_checkBalances);
    final jsonList = cards.map((card) => jsonEncode(card.toJson())).toList();
    await _prefs.setStringListWithTransactions(
      _cardsKey,
      jsonList,
      [for (final tx in transactions) MoneyTrackerRepository.toRow(tx)],
    );
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
