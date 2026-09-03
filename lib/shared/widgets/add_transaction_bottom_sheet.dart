import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/home/controller/home/home_notifier.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/transactions/controller/transactions/transactions_notifier.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

enum TransactionType { expense, income, transfer }

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  const AddTransactionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
  late TextEditingController _noteController;

  DateTime _selectedDate = DateTime.now();
  String? _sourceWallet;
  String? _destinationWallet;
  String? _selectedCategory;
  double _swapTurns = 0.0;

  final List<String> _categories = [
    'Food & Drink',
    'Shopping',
    'Travel',
    'Entertainment',
    'Loan',
    'Grocery',
  ];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '0');
    _noteController = TextEditingController();
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

    final walletState = ref.watch(walletNotifierProvider);
    final cardWallets = walletState.cards
        .map((c) => c.bankName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final List<String> wallets = cardWallets.isNotEmpty
        ? [
            ...cardWallets,
            if (!cardWallets.any((w) => w.toLowerCase() == 'cash')) 'Cash',
          ]
        : ['Cash'];

    final selectedSource = (wallets.contains(_sourceWallet))
        ? _sourceWallet!
        : wallets.first;

    final selectedDestination = (wallets.contains(_destinationWallet) && _destinationWallet != selectedSource)
        ? _destinationWallet!
        : (wallets.length > 1
            ? wallets.firstWhere((w) => w != selectedSource, orElse: () => wallets.first)
            : selectedSource);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 40),
      child: SingleChildScrollView(
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
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _amountController,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
                decoration: const InputDecoration(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Assets.icons.wallet.svg(
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF8E8E93),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSource,
                        icon: Assets.icons.dropDown.svg(
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF111111),
                            BlendMode.srcIn,
                          ),
                        ),
                        isExpanded: true,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111111),
                        ),
                        items: wallets
                            .map(
                              (w) => DropdownMenuItem(
                                value: w,
                                child: Text(w),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _sourceWallet = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Field 3: Category OR Destination Wallet (with Swap Button for Transfer)
            if (_selectedType == TransactionType.transfer)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Destination Wallet Field
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Assets.icons.wallet.svg(
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF8E8E93),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedDestination,
                              icon: Assets.icons.dropDown.svg(
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF111111),
                                  BlendMode.srcIn,
                                ),
                              ),
                              isExpanded: true,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111111),
                              ),
                              items: wallets
                                  .map(
                                    (w) => DropdownMenuItem(
                                      value: w,
                                      child: Text(w),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _destinationWallet = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
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
              // Category Field for Expense / Income
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF9E9EA5),
                            ),
                          ),
                          icon: Assets.icons.dropDown.svg(
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF111111),
                              BlendMode.srcIn,
                            ),
                          ),
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111111),
                          ),
                          items: _categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          },
                        ),
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
                onPressed: () {
                  final amount = double.tryParse(_amountController.text) ?? 0.0;
                  final note = _noteController.text.trim();
                  final title = _selectedType == TransactionType.transfer
                      ? 'Transfer to $selectedDestination'
                      : (_selectedCategory ?? 'Transaction');
                  
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
                    currency: 'INR',
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
                    currency: 'INR',
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Save transaction',
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
