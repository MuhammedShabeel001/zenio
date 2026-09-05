import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/transactions/presentation/widgets/manage_categories_bottom_sheet.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/presentation/widgets/add_wallet_bottom_sheet.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/zenio_dropdown.dart';

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
      txModel = TransactionModel(
        id: transaction.id,
        title: transaction.title,
        date: transaction.date,
        amount: transaction.amount,
        isIncome: transaction.isIncome,
        currency: transaction.currency,
        note: transaction.note,
        bankName: transaction.bankName,
        timestamp: transaction.timestamp,
      );
    } else if (transaction is TransactionModel) {
      txModel = transaction;
    } else {
      throw ArgumentError('Invalid transaction type passed to EditTransactionDialog');
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

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;

    final title = tx.title;
    _isIncome = tx.isIncome;
    _isTransfer = title.startsWith('Transfer to');

    if (_isTransfer) {
      final parts = title.split('Transfer to ');
      if (parts.length > 1) {
        _destinationWallet = parts[1].trim();
      }
    } else {
      _selectedCategory = title;
    }

    final amount = tx.amount;
    _amountController = TextEditingController(
      text: amount == amount.toInt() ? amount.toInt().toString() : amount.toString(),
    );

    _noteController = TextEditingController(text: tx.note ?? '');
    _sourceWallet = tx.bankName ?? 'Cash';

    // Parse date safely
    _selectedDate = DateTime.now();
    if (tx.date.isNotEmpty) {
      final dateStr = tx.date;
      try {
        _selectedDate = DateFormat('dd-MM-yyyy').parse(dateStr);
      } catch (_) {
        try {
          _selectedDate = DateFormat('EEEE, MMMM d, yyyy').parse(dateStr);
        } catch (_) {
          try {
            _selectedDate = DateTime.parse(dateStr);
          } catch (_) {}
        }
      }
    }

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

  String _formatAmount(double amount) {
    if (amount == amount.toInt()) {
      return NumberFormat('#,##0').format(amount.toInt());
    }
    return NumberFormat('#,##0.00').format(amount);
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
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);

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
                  color: Color(0xFF8E8E93),
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
    final isDebit = !_isIncome; // Expense and transfer are debit
    final isExceedingBalance = isDebit && enteredAmount > availableBalance;
    final isInvalidAmount = enteredAmount <= 0;
    final canSave = !isExceedingBalance && !isInvalidAmount;
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyCode = ref.watch(currencyCodeProvider);

    final dialogTitle = _isTransfer
        ? 'Edit Transfer'
        : (_isIncome ? 'Edit Income' : 'Edit Expense');

    final badgeColor = _isTransfer
        ? const Color(0xFF8949D5)
        : (_isIncome ? const Color(0xFF10B981) : const Color(0xFFDD3D34));

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header with Type Badge and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        dialogTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111111),
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
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F2),
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
                ],
              ),
              const SizedBox(height: 16),

              // Amount Input Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: isExceedingBalance
                      ? Border.all(color: const Color(0xFFDD3D34), width: 1.5)
                      : null,
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

              // Source Wallet Selector
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
                    subtitleColor: !hasEnough
                        ? const Color(0xFFDD3D34)
                        : const Color(0xFF8E8E93),
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

              // Category Selector (or Destination Wallet for Transfer)
              if (_isTransfer) ...[
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
              ] else ...[
                // Category Chips Section
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
                                (_selectedCategory == null && cat == categories.first);
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
              ],
              const SizedBox(height: 6),

              // Note Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
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
                      fontSize: 14,
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

              // Date Picker Field
              GestureDetector(
                onTap: _pickDate,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
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
              const SizedBox(height: 16),

              // Save Changes Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: canSave
                      ? () {
                          final amount =
                              double.tryParse(_amountController.text) ?? 0.0;
                          if (amount <= 0) return;

                          final note = _noteController.text.trim();

                          final String title;
                          final bankName = selectedSource;

                          if (_isTransfer) {
                            title = 'Transfer to $selectedDestination';
                          } else {
                            title = _selectedCategory ??
                                (categories.isNotEmpty
                                    ? categories.first.name
                                    : 'General');
                          }

                          final updatedTx = TransactionModel(
                            id: widget.transaction.id,
                            title: title,
                            date: formattedDate,
                            amount: amount,
                            isIncome: _isIncome,
                            currency: currencyCode,
                            note: note.isNotEmpty ? note : null,
                            bankName: bankName,
                            timestamp: widget.transaction.timestamp,
                          );

                          ref
                              .read(homeNotifierProvider.notifier)
                              .updateTransaction(updatedTx);
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSave
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE0E0E0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    isExceedingBalance
                        ? 'Insufficient Wallet Balance'
                        : (isInvalidAmount
                            ? 'Enter a Valid Amount'
                            : 'Save Changes'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: canSave ? Colors.white : const Color(0xFF9E9EA5),
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
