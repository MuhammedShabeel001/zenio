import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/transactions/controller/transactions/transactions_notifier.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/presentation/widgets/manage_categories_bottom_sheet.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/presentation/widgets/add_wallet_bottom_sheet.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/zenio_dropdown.dart';

enum TransactionType { expense, income, transfer }

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  const AddTransactionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionBottomSheet(),
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
    if (amount == amount.toInt()) {
      return NumberFormat('#,##0').format(amount.toInt());
    }
    return NumberFormat('#,##0.00').format(amount);
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
                color: const Color(0xFFD1D1D6),
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
                  color: Color(0xFF8E8E93),
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
                  backgroundColor: const Color(0xFF10B981),
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
    final availableBalance = selectedSourceCard?.balance ?? 0.0;
    final isSourceFrozen = selectedSourceCard?.isFrozen ?? false;

    // Live amount validation
    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final isDebit = _selectedType == TransactionType.expense || _selectedType == TransactionType.transfer;
    final isExceedingBalance = isDebit && enteredAmount > availableBalance;
    final isInvalidAmount = enteredAmount <= 0;
    final canSave = !isExceedingBalance && !isInvalidAmount;
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyCode = ref.watch(currencyCodeProvider);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                  color: const Color(0xFFD1D1D6),
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
                    activeColor: const Color(0xFFDD3D34),
                  ),
                  _buildTabItem(
                    type: TransactionType.income,
                    label: 'Income',
                    activeColor: const Color(0xFF10B981),
                  ),
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
                    : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isExceedingBalance
                      ? const Color(0xFFDD3D34)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '$currencySymbol ',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isExceedingBalance
                          ? const Color(0xFFDD3D34)
                          : const Color(0xFF111111),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      onChanged: (val) {
                        if (val.length > 1 && val.startsWith('0') && !val.startsWith('0.')) {
                          final newText = val.replaceFirst(RegExp(r'^0+'), '');
                          _amountController.value = TextEditingValue(
                            text: newText.isEmpty ? '0' : newText,
                            selection: TextSelection.collapsed(offset: newText.length),
                          );
                        }
                        setState(() {});
                      },
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isExceedingBalance
                            ? const Color(0xFFDD3D34)
                            : const Color(0xFF111111),
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9E9EA5),
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
                        color: Color(0xFFDD3D34),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Amount exceeds wallet balance (Available: $currencySymbol ${_formatAmount(availableBalance)} in $selectedSource). Change wallet or enter a valid amount.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDD3D34),
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

            // Field 1: Date Selector
            GestureDetector(
              onTap: _pickDate,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                    const Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
            ),
             const SizedBox(height: 6),

            // Field 2: Source Wallet Selector
            ZenioDropdown<String>(
              value: selectedSource,
              leadingIcon: Assets.icons.wallet.svg(
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF8E8E93),
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
                  subtitle: '$currencySymbol ${_formatAmount(bal)}',
                  subtitleColor: hasEnough
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFFDD3D34),
                  icon: Assets.icons.wallet.svg(
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF8E8E93),
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

            // Field 3: Category OR Destination Wallet (with Swap Button for Transfer)
            if (_selectedType == TransactionType.transfer)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Destination Wallet Field
                  ZenioDropdown<String>(
                    value: selectedDestination,
                    leadingIcon: Assets.icons.wallet.svg(
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF8E8E93),
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
                            Color(0xFF8E8E93),
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

                  // Floating Circular Swap Button (⇄)
                  Positioned(
                    right: 60,
                    top: -26,
                    child: GestureDetector(
                      onTap: () => _swapWallets(selectedSource, selectedDestination),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 5,
                          ),
                        ),
                        child: Center(
                          child: AnimatedRotation(
                            turns: _swapTurns,
                            duration: const Duration(milliseconds: 300),
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
                ],
              )
            else
              // Category Chips Section for Expense / Income
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8E8E93),
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
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Manage',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: categories.map((cat) {
                            final isSelected = _selectedCategory == cat.name ||
                                (_selectedCategory == null &&
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
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF10B981)
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
                                              : const Color(0xFF111111),
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
            const SizedBox(height: 6),

            // Field 4: Note Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 3,
                minLines: 2,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF111111),
                ),
                decoration: const InputDecoration(
                  hintText: 'Add a note...',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9E9EA5),
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

            // Save Transaction Button
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: canSave
                    ? () {
                        final amount = double.tryParse(_amountController.text) ?? 0.0;
                        final note = _noteController.text.trim();
                        final title = _selectedType == TransactionType.transfer
                            ? 'Transfer to $selectedDestination'
                            : (_selectedCategory ??
                                (categories.isNotEmpty
                                    ? categories.first.name
                                    : 'Transaction'));
                        
                        final isIncome = _selectedType == TransactionType.income;
                        final formattedDate = DateFormat('dd-MM-yyyy').format(_selectedDate);
                        final timeString = DateFormat('HH : mm').format(DateTime.now());
                        final timestamp = '${DateFormat('yy-MM-dd').format(_selectedDate)}   $timeString';
                        final bankName = _selectedType == TransactionType.transfer
                            ? '$selectedSource -> $selectedDestination'
                            : selectedSource;

                        final id = DateTime.now().millisecondsSinceEpoch.toString();

                        final txDetail = TransactionDetailModel(
                          id: id,
                          title: title,
                          date: formattedDate,
                          amount: amount,
                          isIncome: isIncome,
                          currency: currencyCode,
                          note: note.isNotEmpty ? note : null,
                          bankName: bankName,
                          timestamp: timestamp,
                        );

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
                        );

                        ref.read(transactionsNotifierProvider.notifier).addTransaction(txDetail);
                        ref.read(homeNotifierProvider.notifier).addTransaction(txHome);

                        final walletNotifier = ref.read(walletNotifierProvider.notifier);
                        if (_selectedType == TransactionType.expense) {
                          walletNotifier.adjustWalletBalance(
                            walletName: selectedSource,
                            amount: amount,
                            isIncome: false,
                          );
                        } else if (_selectedType == TransactionType.income) {
                          walletNotifier.adjustWalletBalance(
                            walletName: selectedSource,
                            amount: amount,
                            isIncome: true,
                          );
                        } else if (_selectedType == TransactionType.transfer) {
                          walletNotifier.transferBetweenWallets(
                            fromWallet: selectedSource,
                            toWallet: selectedDestination,
                            amount: amount,
                          );
                        }

                        Navigator.of(context).pop();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  disabledBackgroundColor: const Color(0xFFE5E5EA),
                  disabledForegroundColor: const Color(0xFF8E8E93),
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
                    color: canSave ? Colors.white : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
            // Extends white background behind keyboard — not visible, prevents dark gap
            SizedBox(height: bottomInset),
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
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF2F2F2) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w300,
                color: isSelected ? activeColor : const Color(0xFF808080),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
