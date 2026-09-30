import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/repositories/implementations/wallet_repository.dart';
import 'package:zenio/features/wallet/domain/repositories/interfaces/i_wallet_repository.dart';
import 'package:zenio/features/wallet/domain/wallet_balances.dart';
import 'package:zenio/shared/utils/serial_task_queue.dart';

part 'wallet_notifier.freezed.dart';
part 'wallet_notifier.g.dart';
part 'wallet_state.dart';

/// Wallets and their balances.
///
/// A wallet's balance is not edited directly: it is its opening balance plus
/// its transactions (see `wallet_balances.dart`). Manual corrections are
/// recorded as balance-adjustment transactions, so balances follow every
/// added, edited, deleted or imported transaction automatically.
@Riverpod(keepAlive: true)
class WalletNotifier extends _$WalletNotifier {
  IWalletRepository? _walletRepository;
  Future<void>? _initialLoad;
  final _writes = SerialTaskQueue();

  @override
  WalletState build() {
    try {
      _walletRepository = ref.watch(walletRepositoryRepoProvider);
      _initialLoad = Future.microtask(loadWalletData);
    } catch (_) {
      // Local storage is still opening; this notifier rebuilds once it is.
      _walletRepository = null;
      _initialLoad = null;
    }

    // Balances are derived from the transactions, so follow them.
    ref.listen(
      homeNotifierProvider.select((s) => s.transactions),
      (_, transactions) => _onTransactionsChanged(transactions),
    );

    return WalletState.initial();
  }

  double _calculateTotalBalance(List<WalletCardModel> cards) {
    return cards.where((c) => !c.isFrozen).fold(0, (sum, c) => sum + c.balance);
  }

  Future<void> loadWalletData() async {
    final repo = _walletRepository;
    if (repo == null) return;
    state = state.copyWith(status: WalletStatus.loading);
    try {
      final transactions =
          await ref.read(homeNotifierProvider.notifier).loadedTransactions();
      var cards = await repo.getCards();

      // One-time move to derived balances. Opening balances are chosen so
      // every wallet keeps showing exactly the balance it showed before.
      if (cards.any((c) => c.openingBalance == null)) {
        await repo.backupCardsBeforeMigration();
        cards = withOpeningBalances(cards, transactions);
        await repo.saveCards(cards);
      }

      _publish(withDerivedBalances(cards, transactions));
    } catch (e) {
      // Without the transactions the stored balances are the best known
      // values; show them rather than nothing.
      try {
        final cards = await repo.getCards();
        state = state.copyWith(
          cards: cards,
          cardBalance: _calculateTotalBalance(cards),
        );
      } catch (_) {}
      state = state.copyWith(status: WalletStatus.error);
    }
  }

  void _publish(List<WalletCardModel> cards, {int? activeCardIndex}) {
    var newActiveIndex = activeCardIndex ?? state.activeCardIndex;
    if (cards.isEmpty) {
      newActiveIndex = 0;
    } else if (newActiveIndex >= cards.length) {
      newActiveIndex = cards.length - 1;
    }
    state = state.copyWith(
      status: WalletStatus.success,
      cards: cards,
      cardBalance: _calculateTotalBalance(cards),
      activeCardIndex: newActiveIndex,
    );
  }

  /// Recomputes balances after any transaction change and refreshes the
  /// stored balance cache.
  void _onTransactionsChanged(List<TransactionModel> transactions) {
    if (state.status == WalletStatus.error) {
      // The transactions may be readable now; try the full load again.
      loadWalletData().ignore();
      return;
    }
    if (state.status != WalletStatus.success) return;
    _mutate((cards) => cards).ignore();
  }

  List<TransactionModel> get _transactions =>
      ref.read(homeNotifierProvider).transactions;

  void onCardPageChanged(int index) {
    state = state.copyWith(activeCardIndex: index);
  }

  /// Applies [change] to the stored cards (not the in-memory copy) once the
  /// initial load has finished, one write at a time, and publishes the result.
  /// [change] returns null to leave everything untouched.
  ///
  /// Balances are always recomputed from the current transactions. With
  /// [keepBalances], adding, renaming or removing a wallet does not change
  /// any balance the user sees: wallets named in older transactions (for
  /// example of a deleted wallet with the same name) absorb them into their
  /// opening balance, as the migration did. [newBalances] gives the balance
  /// to show for added wallets.
  Future<List<WalletCardModel>?> _mutate(
    List<WalletCardModel>? Function(List<WalletCardModel> current) change, {
    int? activeCardIndex,
    bool keepBalances = false,
    Map<String, double> newBalances = const {},
  }) {
    return _writes.run(() async {
      final repo = _walletRepository;
      if (repo == null) {
        throw StateError('Local storage is not ready yet.');
      }
      await _initialLoad;
      final transactions = _transactions;
      final current = await repo.getCards();
      final changed = change(current);
      if (changed == null) return null;

      var updated = changed;
      if (keepBalances) {
        final shown = {
          for (final card in withDerivedBalances(current, transactions))
            card.id: card.balance,
          ...newBalances,
        };
        updated = keepShownBalances(changed, transactions, shown);
      }
      updated = withDerivedBalances(updated, transactions);

      await repo.saveCards(updated);
      await repo.saveCardBalance(_calculateTotalBalance(updated));
      _publish(updated, activeCardIndex: activeCardIndex);
      return updated;
    });
  }

  /// Replaces the card with the same id as [card] in [cards].
  static List<WalletCardModel>? _replaceById(
    List<WalletCardModel> cards,
    WalletCardModel card,
  ) {
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index == -1) return null;
    return List<WalletCardModel>.from(cards)..[index] = card;
  }

  WalletCardModel? _cardAt(int index) {
    if (index < 0 || index >= state.cards.length) return null;
    return state.cards[index];
  }

  /// Whether another wallet already uses [name] (ignoring case and spaces).
  bool isNameTaken(String name, {String? exceptId}) {
    final key = walletNameKey(name);
    return state.cards.any(
      (c) => c.id != exceptId && walletNameKey(c.bankName) == key,
    );
  }

  /// Sets the wallet's balance to [newBalance] by recording the difference as
  /// a balance adjustment, so the change stays visible in the history.
  Future<void> adjustBalance(String walletId, double newBalance) async {
    await _initialLoad;
    final card = state.cards.where((c) => c.id == walletId).firstOrNull;
    if (card == null) return;
    // Transactions name their wallet; with a shared name the adjustment
    // would land on the other wallet.
    final owner = state.cards.firstWhere(
      (c) => walletNameKey(c.bankName) == walletNameKey(card.bankName),
    );
    if (owner.id != card.id) throw const WalletNameConflictException();
    final delta = roundToCents(newBalance - card.balance);
    if (delta == 0) return;

    final now = DateTime.now();
    await ref.read(homeNotifierProvider.notifier).addTransaction(
          TransactionModel(
            id: now.microsecondsSinceEpoch.toString(),
            title: balanceAdjustmentTitle,
            date: DateFormat('dd-MM-yyyy').format(now),
            amount: delta.abs(),
            isIncome: delta > 0,
            currency:
                ref.read(settingsNotifierProvider).settings.primaryCurrency,
            bankName: card.bankName,
            timestamp:
                '${DateFormat('yy-MM-dd').format(now)}   ${DateFormat('HH : mm').format(now)}',
            kind: TransactionKind.adjustment.name,
          ),
        );
  }

  /// Freezes or unfreezes the card at [index] (the card on screen).
  Future<void> toggleFreezeCard(int index) async {
    final target = _cardAt(index);
    if (target == null) return;
    await _mutate(
      (cards) {
        final card = cards.where((c) => c.id == target.id).firstOrNull;
        if (card == null) return null;
        return _replaceById(cards, card.copyWith(isFrozen: !card.isFrozen));
      },
      keepBalances: true,
    );
  }

  Future<void> addCard(WalletCardModel card, double initialBalance) async {
    final newCard = card.copyWith(
      balance: initialBalance,
      openingBalance: initialBalance,
    );
    final updated = await _mutate(
      (cards) => [...cards, newCard],
      keepBalances: true,
      newBalances: {newCard.id: initialBalance},
    );
    if (updated == null) return;

    // If this is the user's first wallet, automatically set as default
    if (updated.length == 1) {
      try {
        await ref
            .read(settingsNotifierProvider.notifier)
            .updateDefaultWallet(card.bankName);
      } catch (_) {}
    }

    // Focus on the newly added card
    state = state.copyWith(activeCardIndex: updated.length - 1);
  }

  /// Updates the wallet's details. Its balance is not changed here (see
  /// [adjustBalance]). Renaming also renames the wallet in its transactions,
  /// so their history and the balance stay with the wallet.
  Future<void> editCard(int index, WalletCardModel newCard) async {
    final oldCard = _cardAt(index);
    if (oldCard == null) return;
    final edited = newCard.copyWith(
      id: oldCard.id,
      balance: oldCard.balance,
      openingBalance: oldCard.openingBalance,
    );

    final renamed =
        walletNameKey(oldCard.bankName) != walletNameKey(edited.bankName);
    // Transactions name their wallet; with duplicate names they belong to the
    // first wallet with that name, so only that one takes them along.
    final ownsTransactions = state.cards
            .firstWhere(
              (c) =>
                  walletNameKey(c.bankName) == walletNameKey(oldCard.bankName),
            )
            .id ==
        oldCard.id;
    final home = ref.read(homeNotifierProvider.notifier);
    if (renamed && ownsTransactions) {
      await home.renameWallet(oldCard.bankName, edited.bankName);
    }

    try {
      final updated = await _mutate(
        (cards) => _replaceById(cards, edited),
        keepBalances: true,
        newBalances: {edited.id: oldCard.balance},
      );
      if (updated == null) throw StateError('Wallet no longer exists.');
    } catch (_) {
      // Keep transactions and wallet consistent if the wallet save failed.
      if (renamed && ownsTransactions) {
        await home.renameWallet(edited.bankName, oldCard.bankName);
      }
      rethrow;
    }

    // If default wallet was renamed, keep default synchronized
    if (renamed) {
      try {
        final currentDefault =
            ref.read(settingsNotifierProvider).settings.defaultWallet;
        if (walletNameKey(currentDefault) == walletNameKey(oldCard.bankName)) {
          await ref
              .read(settingsNotifierProvider.notifier)
              .updateDefaultWallet(edited.bankName);
        }
      } catch (_) {}
    }
  }

  /// Removes the wallet. Its transactions stay in the history.
  Future<void> deleteCard(int index) async {
    final deletedCard = _cardAt(index);
    if (deletedCard == null) return;
    final updated = await _mutate(
      (cards) => cards.where((c) => c.id != deletedCard.id).toList(),
      keepBalances: true,
    );
    if (updated == null) return;

    // If the deleted card was default, update default to next available card
    try {
      final currentDefault =
          ref.read(settingsNotifierProvider).settings.defaultWallet;
      if (walletNameKey(currentDefault) ==
              walletNameKey(deletedCard.bankName) &&
          updated.isNotEmpty) {
        await ref
            .read(settingsNotifierProvider.notifier)
            .updateDefaultWallet(updated.first.bankName);
      }
    } catch (_) {}
  }

  /// How many transactions refer to the wallet at [index].
  int transactionCountFor(int index) {
    final card = _cardAt(index);
    if (card == null) return 0;
    final key = walletNameKey(card.bankName);
    return ref.read(homeNotifierProvider).transactions.where((tx) {
      final ends = parseTransferWallets(tx.bankName);
      if (ends != null) {
        return walletNameKey(ends.from) == key || walletNameKey(ends.to) == key;
      }
      return tx.bankName != null && walletNameKey(tx.bankName!) == key;
    }).length;
  }
}

/// A wallet shares its name with an earlier wallet, so a transaction naming
/// it would be attributed to that other wallet.
class WalletNameConflictException implements Exception {
  const WalletNameConflictException();

  String get message => 'Another wallet has the same name. Rename this '
      'wallet before adjusting its balance.';

  @override
  String toString() => message;
}
