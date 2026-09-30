import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/presentation/widgets/category_picker.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/wallet_kind.dart';
import 'package:zenio/features/wallet/presentation/widgets/add_wallet_bottom_sheet.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/utils/datetime.dart';
import 'package:zenio/shared/utils/formatters.dart';
import 'package:zenio/shared/widgets/money.dart';
import 'package:zenio/shared/widgets/zenio_dropdown.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

class EditTransactionDialog extends ConsumerStatefulWidget {
  const EditTransactionDialog({
    required this.transaction,
    super.key,
  });

  final TransactionModel transaction;

  static Future<void> show(
    BuildContext context, {
    required dynamic transaction,
  }) {
    final TransactionModel txModel;
    if (transaction is TransactionDetailModel) {
      txModel = transaction.toModel();
    } else if (transaction is TransactionModel) {
      txModel = transaction;
    } else {
      throw ArgumentError('Invalid transaction type passed to EditTransactionDialog');
    }

    if (txModel.resolvedKind == TransactionKind.adjustment) {
      // An adjustment only exists to set a balance; changing it here would
      // be confusing. Deleting it and adjusting again is explicit.
      ZenioSnackBar.show(
        context,
        message: 'Balance adjustments can’t be edited. Delete it and use '
            'Adjust on the wallet instead.',
      );
      return Future<void>.value();
    }

    return showDialog<void>(
      context: context,
      builder: (context) => EditTransactionDialog(transaction: txModel),
    );
  }

  @override
  ConsumerState<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends ConsumerState<EditTransactionDialog> {
  late bool _isTransfer;
  late bool _isIncome;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late DateTime _selectedDate;
  String? _sourceWallet;
  String? _destinationWallet;
  String? _selectedCategory;
  bool _isSaving = false;
  String? _saveError;

  /// Keeps the time of [previous] ("yy-MM-dd   HH : mm") but moves it to
  /// [date], so the list order follows an edited date.
  static String _timestampFor(DateTime date, String? previous) {
    final datePart = DateFormat('yy-MM-dd').format(date);
    final timePart = previous != null && previous.contains('   ')
        ? previous.substring(previous.indexOf('   ') + 3)
        : DateFormat('HH : mm').format(DateTime.now());
    return '$datePart   $timePart';
  }

  /// The time of day in a stored timestamp ("yy-MM-dd   HH : mm") as
  /// "HH:mm", or null when it has none.
  static String? _timeOf(String? timestamp) {
    final match =
        RegExp(r'   (\d{1,2}) ?: ?(\d{2})$').firstMatch(timestamp ?? '');
    return match == null ? null : '${match[1]}:${match[2]}';
  }

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;

    final title = tx.title;
    _isIncome = tx.isIncome;
    _isTransfer = tx.resolvedKind == TransactionKind.transfer;

    // Only a transfer names two wallets; any other transaction's wallet is
    // taken whole, even if its name contains "->".
    final transferEnds = tx.transferEnds;
    if (_isTransfer) {
      _destinationWallet = transferEnds?.to ??
          (title.startsWith(transferTitlePrefix)
              ? title.substring(transferTitlePrefix.length).trim()
              : null);
    } else {
      _selectedCategory = title;
    }

    final amount = tx.amount;
    _amountController = TextEditingController(
      text: AppNumberFormat.formatAmount(amount),
    );

    _noteController = TextEditingController(text: tx.note ?? '');
    _sourceWallet = transferEnds?.from ?? tx.bankName ?? 'Cash';

    // Parse date safely
    _selectedDate = DateTimeUtils.parseTransactionDate(tx.date) ?? DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletNotifierProvider.notifier).loadWalletData();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.instrumentSansTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shown under the date; it is kept when the date changes.
    final time = _timeOf(widget.transaction.timestamp);

    final categories = ref.watch(categoriesNotifierProvider);
    final walletState = ref.watch(walletNotifierProvider);

    // If NO wallet is added, prompt to add wallet
    if (walletState.cards.isEmpty) {
      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F3FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Assets.icons.wallet.svg(
                    width: 30,
                    height: 30,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF3B82F6),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No Wallet Added',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000000),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You must add at least one wallet or card before modifying a transaction.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: ZenioColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    AddWalletBottomSheet.show(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZenioColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    '+ Add wallet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // A wallet that was renamed or deleted stays selected (and listed)
    // rather than the transaction silently moving to another wallet.
    final wallets = walletState.cards
        .map((c) => c.bankName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    for (final name in [_sourceWallet, _destinationWallet]) {
      if (name != null && name.trim().isNotEmpty && !wallets.contains(name)) {
        wallets.add(name);
      }
    }

    final selectedSource = (wallets.contains(_sourceWallet))
        ? _sourceWallet!
        : wallets.first;

    final selectedDestination = (wallets.contains(_destinationWallet) && _destinationWallet != selectedSource)
        ? _destinationWallet!
        : (wallets.length > 1
            ? wallets.firstWhere((w) => w != selectedSource, orElse: () => wallets.first)
            : selectedSource);

    // Selected source card & balance
    final selectedSourceCard = walletState.cards.cast<WalletCardModel?>().firstWhere(
      (c) => c?.bankName.trim().toLowerCase() == selectedSource.trim().toLowerCase(),
      orElse: () => null,
    );
    // The wallet balance already includes this transaction, so what it took
    // from the same wallet is available again while editing it.
    final original = widget.transaction;
    final originalSource = original.transferEnds?.from ?? original.bankName;
    final tookFromSameWallet = !original.isIncome &&
        originalSource != null &&
        originalSource.trim().toLowerCase() ==
            selectedSource.trim().toLowerCase();
    final availableBalance = (selectedSourceCard?.balance ?? 0.0) +
        (tookFromSameWallet ? original.amount : 0);
    final isSourceFrozen = selectedSourceCard?.isFrozen ?? false;

    // Live amount validation
    final enteredAmount = AppNumberFormat.parseAmount(_amountController.text);
    final isDebit = !_isIncome; // Expense and transfer are debit
    // Only wallets that still exist have a balance to check against, and a
    // credit card may go below zero.
    final isExceedingBalance = selectedSourceCard != null &&
        !selectedSourceCard.isCredit &&
        isDebit &&
        enteredAmount > availableBalance;
    final isInvalidAmount = enteredAmount <= 0;
    final canSave = !isExceedingBalance && !isInvalidAmount;
    final currencySymbol = ref.watch(currencySymbolProvider);

    final dialogTitle = _isTransfer
        ? 'Edit transfer'
        : (_isIncome ? 'Edit income' : 'Edit expense');

    final badgeColor = _isTransfer
        ? const Color(0xFF8949D5)
        : (_isIncome ? ZenioColors.primary : ZenioColors.danger);

    final badgeText = _isTransfer ? 'Transfer' : (_isIncome ? 'Income' : 'Expense');

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          // As in Add transaction: dragging the form puts the keyboard away.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header with Type Badge and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // On a narrow screen with large text the title wraps
                  // rather than pushing Close off the dialog.
                  Flexible(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            dialogTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ZenioColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Close',
                    excludeSemantics: true,
                    onTap: () => Navigator.of(context).pop(),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      // A 44dp touch area around the 32dp circle.
                      child: SizedBox.square(
                        dimension: 44,
                        child: Center(
                          child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: ZenioColors.fieldFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount Input Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                decoration: BoxDecoration(
                  color: ZenioColors.fieldFill,
                  borderRadius: BorderRadius.circular(20),
                  border: isExceedingBalance
                      ? Border.all(color: ZenioColors.danger, width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    Text(
                      '$currencySymbol ',
                      style: AppFonts.numeric(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isExceedingBalance
                            ? ZenioColors.danger
                            : ZenioColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          ThousandsSeparatorInputFormatter(),
                        ],
                        onChanged: (val) {
                          setState(() {});
                        },
                        style: AppFonts.numeric(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isExceedingBalance
                              ? ZenioColors.danger
                              : ZenioColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: AppFonts.numeric(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ZenioColors.textPlaceholder,
                          ),
                          isDense: true,
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // What a credit card's balance becomes, said plainly.
              if ((selectedSourceCard?.isCredit ?? false) && isDebit && enteredAmount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
                  child: Text(
                    'Balance after transaction: ${Money.balance(availableBalance - enteredAmount, symbol: currencySymbol)}',
                    style: AppFonts.numeric(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ZenioColors.textSecondary,
                    ),
                  ),
                ),
              if (isExceedingBalance)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEAEA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: ZenioColors.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Amount exceeds wallet balance (Available: ${Money.balance(availableBalance, symbol: currencySymbol)} in $selectedSource). Change wallet or enter a valid amount.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ZenioColors.danger,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (isSourceFrozen)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.ac_unit_rounded,
                          color: Color(0xFFD97706),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Note: $selectedSource is currently frozen.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD97706),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 6),

              // Date Picker Field
              GestureDetector(
                onTap: _pickDate,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                  decoration: BoxDecoration(
                    color: ZenioColors.fieldFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: ZenioColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateTimeUtils.displayDate(_selectedDate),
                              style: AppFonts.numeric(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF000000),
                              ),
                            ),
                            if (time != null)
                              Text(
                                time,
                                style: AppFonts.numeric(
                                  fontSize: ZenioFontSizes.caption,
                                  fontWeight: FontWeight.w400,
                                  color: ZenioColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ZenioColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Source Wallet Selector
              ZenioDropdown<String>(
                label: _isTransfer ? 'From' : null,
                value: selectedSource,
                leadingIcon: Assets.icons.wallet.svg(
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    ZenioColors.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                items: wallets.map((w) {
                  final card = walletState.cards
                      .cast<WalletCardModel?>()
                      .firstWhere(
                        (c) =>
                            c?.bankName.trim().toLowerCase() ==
                            w.trim().toLowerCase(),
                        orElse: () => null,
                      );
                  final bal = card?.balance ?? 0.0;
                  final hasEnough = !isDebit || bal >= enteredAmount;
                  return ZenioDropdownItem<String>(
                    value: w,
                    label: w,
                    subtitle: Money.balance(bal, symbol: currencySymbol),
                    subtitleColor: !hasEnough
                        ? ZenioColors.danger
                        : ZenioColors.textSecondary,
                    icon: Assets.icons.wallet.svg(
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        ZenioColors.textSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _sourceWallet = val;
                  });
                },
              ),
              const SizedBox(height: 6),

              // Category Selector (or Destination Wallet for Transfer)
              if (_isTransfer) ...[
                ZenioDropdown<String>(
                  label: 'To',
                  value: selectedDestination,
                  leadingIcon: Assets.icons.wallet.svg(
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      ZenioColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  items: wallets.map((w) {
                    final card = walletState.cards
                        .cast<WalletCardModel?>()
                        .firstWhere(
                          (c) =>
                              c?.bankName.trim().toLowerCase() ==
                              w.trim().toLowerCase(),
                          orElse: () => null,
                        );
                    final bal = card?.balance ?? 0.0;
                    return ZenioDropdownItem<String>(
                      value: w,
                      label: w,
                      subtitle: Money.balance(bal, symbol: currencySymbol),
                      icon: Assets.icons.wallet.svg(
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          ZenioColors.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _destinationWallet = val;
                    });
                  },
                ),
              ] else ...[
                // Category chips, as in Add transaction.
                CategoryPicker(
                  categories: categories,
                  optional: _isIncome,
                  selected: _selectedCategory ??
                      (_isIncome ? null : categories.firstOrNull?.name),
                  onSelected: (name) =>
                      setState(() => _selectedCategory = name),
                ),
              ],
              const SizedBox(height: 6),

              // Note Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                decoration: BoxDecoration(
                  color: ZenioColors.fieldFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: 3,
                  minLines: 2,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ZenioColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: ZenioColors.textPlaceholder,
                    ),
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _saveError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ZenioColors.danger,
                    ),
                  ),
                ),
              // Save Changes Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: canSave && !_isSaving
                      ? () async {
                          final amount =
                              AppNumberFormat.parseAmount(_amountController.text);
                          if (amount <= 0) return;

                          final note = _noteController.text.trim();

                          final String title;
                          final String bankName;
                          final TransactionKind kind;

                          if (_isTransfer) {
                            title = '$transferTitlePrefix$selectedDestination';
                            bankName = transferBankName(
                              selectedSource,
                              selectedDestination,
                            );
                            kind = TransactionKind.transfer;
                          } else {
                            title = _selectedCategory ??
                                (_isIncome
                                    ? 'Income'
                                    : (categories.isNotEmpty
                                        ? categories.first.name
                                        : 'General'));
                            bankName = selectedSource;
                            kind = _isIncome
                                ? TransactionKind.income
                                : TransactionKind.expense;
                          }

                          final savedDate = DateFormat('dd-MM-yyyy').format(_selectedDate);
                          final updatedTx = widget.transaction.copyWith(
                            title: title,
                            date: savedDate,
                            amount: amount,
                            isIncome: _isIncome,
                            note: note.isNotEmpty ? note : null,
                            bankName: bankName,
                            timestamp: _timestampFor(
                              _selectedDate,
                              widget.transaction.timestamp,
                            ),
                            kind: kind.name,
                            // The wallets themselves, not read back from
                            // bankName, so names with "->" stay whole.
                            transferFrom: _isTransfer ? selectedSource : null,
                            transferTo:
                                _isTransfer ? selectedDestination : null,
                          );

                          setState(() => _isSaving = true);
                          try {
                            await ref
                                .read(homeNotifierProvider.notifier)
                                .updateTransaction(updatedTx);
                          } catch (_) {
                            if (!mounted) return;
                            // Shown in the dialog: a snackbar would sit
                            // behind its barrier.
                            setState(() {
                              _isSaving = false;
                              _saveError =
                                  "Couldn't save your changes. Please try again.";
                            });
                            return;
                          }
                          await HapticFeedback.lightImpact();
                          if (!context.mounted) return;
                          ZenioSnackBar.show(
                            context,
                            message: 'Transaction updated',
                            type: ZenioSnackBarType.success,
                          );
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSave
                        ? ZenioColors.primary
                        : const Color(0xFFE0E0E0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    isExceedingBalance
                        ? 'Not enough in this wallet'
                        : 'Save changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: canSave ? Colors.white : ZenioColors.textPlaceholder,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
