import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/transactions/presentation/widgets/manage_categories_bottom_sheet.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/wallet_kind.dart';
import 'package:zenio/features/wallet/presentation/widgets/add_wallet_bottom_sheet.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/providers/default_wallet_provider/default_wallet_provider.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/utils/formatters.dart';
import 'package:zenio/shared/widgets/money.dart';
import 'package:zenio/shared/widgets/zenio_dropdown.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

enum TransactionType { expense, income, transfer }

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  const AddTransactionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: const AddTransactionBottomSheet(),
      ),
    );
  }

  @override
  ConsumerState<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends ConsumerState<AddTransactionBottomSheet> {
  TransactionType _selectedType = TransactionType.expense;

  late TextEditingController _amountController;
  late FocusNode _amountFocusNode;
  late TextEditingController _noteController;

  DateTime _selectedDate = DateTime.now();
  String? _sourceWallet;
  String? _destinationWallet;
  String? _selectedCategory;
  double _swapTurns = 0;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _amountFocusNode = FocusNode();
    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus && _amountController.text == '0') {
        _amountController.clear();
      }
    });
    _noteController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletNotifierProvider.notifier).loadWalletData();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _amountFocusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    return AppNumberFormat.formatAmount(amount);
  }

  void _swapWallets(String currentSource, String currentDestination) {
    setState(() {
      _sourceWallet = currentDestination;
      _destinationWallet = currentSource;
      _swapTurns += 0.5;
    });
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
    final formattedDate =
        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

    final categories = ref.watch(categoriesNotifierProvider);
    final walletState = ref.watch(walletNotifierProvider);

    // 1. If NO wallet is added, the user cannot add a transaction
    if (walletState.cards.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle Indicator
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: ZenioColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),

            // Icon Circle (60x60 pastel badge matching app aesthetic)
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

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'You must add at least one wallet or card before you can add a transaction.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: ZenioColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 56,
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
                  '+ Add Wallet',
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
      );
    }

    final wallets = walletState.cards
        .map((c) => c.bankName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    if (wallets.length < 2 && _selectedType == TransactionType.transfer) {
      _selectedType = TransactionType.expense;
    }

    final defaultWallet = ref.watch(defaultWalletProvider);
    final fallbackWallet = wallets.contains(defaultWallet) ? defaultWallet : wallets.first;

    final selectedSource = (wallets.contains(_sourceWallet))
        ? _sourceWallet!
        : fallbackWallet;

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
    final availableBalance = selectedSourceCard?.balance ?? 0.0;
    final isSourceFrozen = selectedSourceCard?.isFrozen ?? false;
    // A credit card may go below zero: a purchase is never blocked by it.
    final isCreditSource = selectedSourceCard?.isCredit ?? false;

    // Live amount validation
    final enteredAmount = AppNumberFormat.parseAmount(_amountController.text);
    final isDebit = _selectedType == TransactionType.expense || _selectedType == TransactionType.transfer;
    final isExceedingBalance =
        isDebit && !isCreditSource && enteredAmount > availableBalance;
    final showBalanceAfter = isDebit && isCreditSource && enteredAmount > 0;
    final isInvalidAmount = enteredAmount <= 0;
    final canSave = !isExceedingBalance && !isInvalidAmount;
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyCode = ref.watch(currencyCodeProvider);


    // The wallet the money comes from, and for a transfer where it goes.
    Widget sourceField({String? label}) {
      return ZenioDropdown<String>(
        label: label,
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
          final hasEnough = !isDebit ||
              (card?.isCredit ?? false) ||
              bal >= enteredAmount;
          return ZenioDropdownItem<String>(
            value: w,
            label: w,
            subtitle: '$currencySymbol ${_formatAmount(bal)}',
            subtitleColor: hasEnough
                ? ZenioColors.textSecondary
                : ZenioColors.danger,
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
      );
    }

    Widget destinationField() {
      return ZenioDropdown<String>(
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
            subtitle: '$currencySymbol ${_formatAmount(bal)}',
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
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle Indicator
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: ZenioColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 26),

            // Segmented Mode Switcher (Expense, Income, Transfer)
            Container(
              height: 60,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFCCCCCC),
                ),
              ),
              child: Row(
                children: [
                  _buildTabItem(
                    type: TransactionType.expense,
                    label: 'Expense',
                    activeColor: ZenioColors.danger,
                  ),
                  _buildTabItem(
                    type: TransactionType.income,
                    label: 'Income',
                    activeColor: ZenioColors.primaryStrong,
                  ),
                  if (wallets.length >= 2)
                    _buildTabItem(
                      type: TransactionType.transfer,
                      label: 'Transfer',
                      activeColor: const Color(0xFF8949D5),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Amount Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: isExceedingBalance
                    ? const Color(0xFFFFF5F5)
                    : ZenioColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isExceedingBalance
                      ? ZenioColors.danger
                      : Colors.transparent,
                  width: 1.5,
                ),
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
                      focusNode: _amountFocusNode,
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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

            // Balance notes and warnings ease in and out instead of making
            // the form jump.
            AnimatedSize(
              duration: ZenioMotion.of(context, ZenioMotion.standard),
              curve: ZenioMotion.standardCurve,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // What a credit card's balance becomes, said plainly.
                if (showBalanceAfter)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
                    child: Text(
                      'Balance after transaction: ${Money.balance(availableBalance - enteredAmount, symbol: currencySymbol, alwaysShowDecimals: true)}',
                      style: AppFonts.numeric(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ZenioColors.textSecondary,
                      ),
                    ),
                  ),

                // Live Error Banner if Exceeding Balance or Frozen
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
                              'Amount exceeds wallet balance (Available: $currencySymbol ${_formatAmount(availableBalance)} in $selectedSource). Change wallet or enter a valid amount.',
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
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Field 1: Date Selector
            GestureDetector(
              onTap: _pickDate,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
                      child: Text(
                        formattedDate,
                        style: AppFonts.numeric(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF000000),
                        ),
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

            // Field 2 & 3: the wallet and a category, or for a transfer the
            // From and To wallets with a swap button between them.
            if (_selectedType == TransactionType.transfer)
              Stack(
                children: [
                  Column(
                    children: [
                      sourceField(label: 'From'),
                      const SizedBox(height: 6),
                      destinationField(),
                    ],
                  ),
                  // Straddles the two fields, inside the Stack so all of it
                  // can be tapped.
                  Positioned(
                    right: 60,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Semantics(
                        button: true,
                        label: 'Swap From and To wallets',
                        excludeSemantics: true,
                        onTap: () =>
                            _swapWallets(selectedSource, selectedDestination),
                        child: GestureDetector(
                          onTap: () =>
                              _swapWallets(selectedSource, selectedDestination),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: ZenioColors.fieldFill,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 5,
                              ),
                            ),
                            child: Center(
                              child: AnimatedRotation(
                                turns: _swapTurns,
                                duration: ZenioMotion.standard,
                                curve: Curves.easeInOut,
                                child: Assets.icons.swap.svg(
                                  width: 22,
                                  height: 22,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF8C43E6),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              sourceField(),
              const SizedBox(height: 6),
              // Category Chips Section for Expense / Income
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: ZenioColors.fieldFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The Manage link's tap area reaches into the row's padding
                    // and the gap below, so the row keeps its height.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 1, 6, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedType == TransactionType.income
                                  ? 'Category (optional)'
                                  : 'Category',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: ZenioColors.textSecondary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final picked =
                                  await ManageCategoriesBottomSheet.show(context);
                              if (picked != null) {
                                setState(() {
                                  _selectedCategory = picked.name;
                                });
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Semantics(
                              button: true,
                              label: 'Manage categories',
                              excludeSemantics: true,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 14,
                                      color: ZenioColors.primaryStrong,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Manage',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: ZenioColors.primaryStrong,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: categories.map((cat) {
                            // The first category is only a default for spending; income is
                            // never filed under "Food" unless the user picks it.
                            final isSelected = _selectedCategory == cat.name ||
                                (_selectedCategory == null &&
                                    _selectedType == TransactionType.expense &&
                                    cat == categories.first);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = cat.name;
                                  });
                                },
                                behavior: HitTestBehavior.opaque,
                                child: AnimatedContainer(
                                  duration: ZenioMotion.fast,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? ZenioColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        Text(
                                          cat.emoji,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        cat.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : ZenioColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),

            // Field 4: Note Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
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
            const SizedBox(height: 6),

            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  _saveError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ZenioColors.danger,
                  ),
                ),
              ),
            // Save Transaction Button
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: canSave && !_isSaving
                    ? () async {
                        final amount = AppNumberFormat.parseAmount(_amountController.text);
                        final note = _noteController.text.trim();
                        final title = switch (_selectedType) {
                          TransactionType.transfer =>
                            '$transferTitlePrefix$selectedDestination',
                          // Income without a chosen category is just Income.
                          TransactionType.income =>
                            _selectedCategory ?? 'Income',
                          TransactionType.expense => _selectedCategory ??
                              (categories.isNotEmpty
                                  ? categories.first.name
                                  : 'Transaction'),
                        };
                        
                        final isIncome = _selectedType == TransactionType.income;
                        final formattedDate = DateFormat('dd-MM-yyyy').format(_selectedDate);
                        final timeString = DateFormat('HH : mm').format(DateTime.now());
                        final timestamp = '${DateFormat('yy-MM-dd').format(_selectedDate)}   $timeString';
                        final bankName = _selectedType == TransactionType.transfer
                            ? '$selectedSource$transferWalletSeparator$selectedDestination'
                            : selectedSource;

                        final id = DateTime.now().millisecondsSinceEpoch.toString();

                        final txHome = TransactionModel(
                          id: id,
                          title: title,
                          date: formattedDate,
                          amount: amount,
                          isIncome: isIncome,
                          currency: currencyCode,
                          note: note.isNotEmpty ? note : null,
                          bankName: bankName,
                          timestamp: timestamp,
                          kind: switch (_selectedType) {
                            TransactionType.expense => TransactionKind.expense.name,
                            TransactionType.income => TransactionKind.income.name,
                            TransactionType.transfer => TransactionKind.transfer.name,
                          },
                        );

                        // Wallet balances follow from the saved transaction.
                        setState(() => _isSaving = true);
                        try {
                          await ref.read(homeNotifierProvider.notifier).addTransaction(txHome);
                        } catch (_) {
                          if (!mounted) return;
                          // Keep what was typed; show why above the button.
                          setState(() {
                            _isSaving = false;
                            _saveError =
                                "Couldn't save the transaction. Please try again.";
                          });
                          return;
                        }

                        await HapticFeedback.lightImpact();
                        if (!context.mounted) return;
                        // A short confirmation: the new item may be dated
                        // outside what the screen behind shows.
                        final what = switch (_selectedType) {
                          TransactionType.expense => 'Expense added · $title',
                          TransactionType.income => 'Income added · $title',
                          TransactionType.transfer =>
                            'Transfer added · $selectedSource → $selectedDestination',
                        };
                        ZenioSnackBar.show(
                          context,
                          message:
                              '$what · ${Money.signed(amount, symbol: currencySymbol, direction: MoneyDirection.neutral)}',
                          type: ZenioSnackBarType.success,
                        );
                        Navigator.of(context).pop();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZenioColors.primary,
                  disabledBackgroundColor: const Color(0xFFE5E5EA),
                  disabledForegroundColor: ZenioColors.textSecondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  isExceedingBalance
                      ? 'Insufficient Wallet Balance'
                      : 'Save transaction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: canSave ? Colors.white : ZenioColors.textSecondary,
                  ),
                ),
              ),
            ),
            // Extends white background behind keyboard
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required TransactionType type,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = type;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: ZenioMotion.of(context, ZenioMotion.fast),
            curve: ZenioMotion.standardCurve,
            decoration: BoxDecoration(
              color: isSelected ? ZenioColors.fieldFill : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                  color: isSelected ? activeColor : ZenioColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
