import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/utils/formatters.dart';
import 'package:zenio/shared/widgets/zenio_dropdown.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';


class AddWalletBottomSheet extends ConsumerStatefulWidget {
  const AddWalletBottomSheet({
    this.editingCard,
    this.editingIndex,
    this.isFirstWallet = false,
    super.key,
  });

  final WalletCardModel? editingCard;
  final int? editingIndex;
  final bool isFirstWallet;

  static Future<bool?> show(
    BuildContext context, {
    WalletCardModel? editingCard,
    int? editingIndex,
    bool isFirstWallet = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: AddWalletBottomSheet(
          editingCard: editingCard,
          editingIndex: editingIndex,
          isFirstWallet: isFirstWallet,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddWalletBottomSheet> createState() =>
      _AddWalletBottomSheetState();
}

class _AddWalletBottomSheetState extends ConsumerState<AddWalletBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _customTypeController = TextEditingController();
  String _selectedType = 'DEBIT CARD';
  bool _isCustom = false;
  final List<String> _customTypes = [];
  int _selectedImageIndex = 0;

  static const List<Map<String, String>> _presetTypes = [
    {'value': 'BANK', 'label': 'Bank'},
    {'value': 'DEBIT CARD', 'label': 'Debit'},
    {'value': 'CREDIT CARD', 'label': 'Credit'},
    {'value': 'CASH', 'label': 'Cash'},
    {'value': 'SAVINGS', 'label': 'Savings'},
  ];

  // Card background images
  final List<String> _cardImages = [
    Assets.images.card001.path,
    Assets.images.card002.path,
    Assets.images.card003.path,
    Assets.images.card004.path,
    Assets.images.card005.path,
    Assets.images.card006.path,
    Assets.images.card007.path,
    Assets.images.card008.path,
  ];

  @override
  void initState() {
    super.initState();
    // Load existing custom types from saved cards
    final existingCards = ref.read(walletNotifierProvider).cards;
    for (final c in existingCards) {
      final upper = c.cardType.toUpperCase();
      final isPreset = _presetTypes.any(
        (p) =>
            p['value'] == upper ||
            (upper == 'DEBIT' && p['value'] == 'DEBIT CARD') ||
            (upper == 'CREDIT' && p['value'] == 'CREDIT CARD'),
      );
      if (!isPreset &&
          c.cardType.trim().isNotEmpty &&
          !_customTypes.contains(c.cardType.trim())) {
        _customTypes.add(c.cardType.trim());
      }
    }

    if (widget.editingCard != null) {
      final card = widget.editingCard!;
      _nameController.text = card.bankName;
      _balanceController.text = AppNumberFormat.formatAmount(card.balance);

      final upper = card.cardType.toUpperCase();
      final matchPreset = _presetTypes.firstWhere(
        (p) =>
            p['value'] == upper ||
            (upper == 'DEBIT' && p['value'] == 'DEBIT CARD') ||
            (upper == 'CREDIT' && p['value'] == 'CREDIT CARD'),
        orElse: () => {},
      );
      if (matchPreset.isNotEmpty) {
        _selectedType = matchPreset['value']!;
      } else {
        if (!_customTypes.contains(card.cardType)) {
          _customTypes.add(card.cardType);
        }
        _selectedType = card.cardType;
      }

      final imgPath = card.gradientStartHex.startsWith('image:')
          ? card.gradientStartHex.substring(6)
          : card.gradientStartHex;
      final index = _cardImages.indexOf(imgPath);
      if (index != -1) {
        _selectedImageIndex = index;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  void _applyCustomType() {
    final text = _customTypeController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!_customTypes.contains(text)) {
        _customTypes.add(text);
      }
      _selectedType = text;
      _isCustom = false;
    });
  }

  List<ZenioDropdownItem<String>> _buildDropdownItems() {
    final items = <ZenioDropdownItem<String>>[];

    for (final preset in _presetTypes) {
      items.add(
        ZenioDropdownItem<String>(
          value: preset['value']!,
          label: preset['label']!,
          icon: Assets.icons.card.svg(
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              ZenioColors.textSecondary,
              BlendMode.srcIn,
            ),
          ),
        ),
      );
    }

    for (final custom in _customTypes) {
      if (!_presetTypes.any((p) => p['value'] == custom)) {
        items.add(
          ZenioDropdownItem<String>(
            value: custom,
            label: custom,
            icon: Assets.icons.card.svg(
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                ZenioColors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
        );
      }
    }

    items.add(
      const ZenioDropdownItem<String>(
        value: '__CUSTOM__',
        label: 'Custom...',
        labelColor: ZenioColors.primary,
        icon: Icon(Icons.add_rounded, size: 18, color: ZenioColors.primary),
      ),
    );

    return items;
  }

  bool _isSaving = false;
  String? _nameError;

  Future<void> _onCreateWallet() async {
    if (_isSaving) return;
    var name = _nameController.text.trim();
    if (name.isEmpty) {
      if (widget.isFirstWallet) {
        name = 'Main Wallet';
      } else {
        setState(() => _nameError = 'Enter a wallet name');
        return;
      }
    }
    final notifier = ref.read(walletNotifierProvider.notifier);
    if (notifier.isNameTaken(name, exceptId: widget.editingCard?.id)) {
      setState(() => _nameError = 'You already have a wallet with this name');
      return;
    }

    final balance = AppNumberFormat.parseAmount(_balanceController.text);
    final isEditing = widget.editingCard != null;

    final selectedImage = _cardImages[_selectedImageIndex];

    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final formattedDate = '${months[now.month - 1]} ${now.day}, ${now.year}';

    var finalType = _selectedType;
    if (_selectedType == '__CUSTOM__' || _isCustom) {
      final customText = _customTypeController.text.trim();
      if (customText.isNotEmpty) {
        finalType = customText;
      } else {
        finalType = 'CUSTOM';
      }
    }

    final newCard = WalletCardModel(
      id: isEditing ? widget.editingCard!.id : DateTime.now().toIso8601String(),
      bankName: name,
      // No made-up card number: a card's last four digits can be added
      // when editing it.
      cardNumber: isEditing ? widget.editingCard!.cardNumber : '',
      cardType: finalType,
      gradientStartHex: 'image:$selectedImage',
      gradientEndHex: 'image:$selectedImage',
      balance: isEditing ? widget.editingCard!.balance : balance,
      createdAt: isEditing ? widget.editingCard!.createdAt : formattedDate,
      isFrozen: isEditing && widget.editingCard!.isFrozen,
    );

    setState(() {
      _isSaving = true;
      _nameError = null;
    });
    try {
      if (isEditing && widget.editingIndex != null) {
        await notifier.editCard(widget.editingIndex!, newCard);
      } else {
        await notifier.addCard(newCard, balance);
      }
    } catch (_) {
      if (!mounted) return;
      // Shown in the sheet: a snackbar would appear behind it.
      setState(() {
        _isSaving = false;
        _nameError = "Couldn't save the wallet. Please try again.";
      });
      return;
    }

    if (!mounted) return;
    if (!isEditing) {
      unawaited(HapticFeedback.lightImpact());
      ZenioSnackBar.show(
        context,
        message: 'Wallet added · $name',
        type: ZenioSnackBarType.success,
      );
    }
    Navigator.of(context).pop(true);
  }

  /// A credit card may start below zero (money already owed on it).
  bool get _typeIsCredit {
    final type = _selectedType == '__CUSTOM__' || _isCustom
        ? _customTypeController.text
        : _selectedType;
    return type.toUpperCase().contains('CREDIT');
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
            const SizedBox(height: 20),

            if (widget.isFirstWallet) ...[
              Text(
                'Add your first wallet',
                style: AppFonts.text(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ZenioColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set up your starting balance and wallet name to begin.',
                style: AppFonts.text(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: ZenioColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
            ] else ...[
              const SizedBox(height: 6),
            ],

            // Initial Balance (Amount) Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: ZenioColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    '$currencySymbol ',
                    style: AppFonts.numeric(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.editingCard != null
                          ? Colors.black54
                          : ZenioColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _balanceController,
                      readOnly: widget.editingCard != null,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                        signed: _typeIsCredit,
                      ),
                      inputFormatters: [
                        ThousandsSeparatorInputFormatter(
                          allowNegative: _typeIsCredit,
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {});
                      },
                      style: AppFonts.numeric(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.editingCard != null
                            ? Colors.black54
                            : ZenioColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
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
            const SizedBox(height: 6),

            // Field 1: Wallet Name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              decoration: BoxDecoration(
                color: ZenioColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Assets.icons.wallet.svg(
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      ZenioColors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ZenioColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Wallet name',
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
                ],
              ),
            ),
            if (_nameError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Text(
                  _nameError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ZenioColors.danger,
                  ),
                ),
              ),
            const SizedBox(height: 6),

            // Field 2: Wallet Type Dropdown
            ZenioDropdown<String>(
              value: _selectedType,
              leadingIcon: Assets.icons.card.svg(
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  ZenioColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
              items: _buildDropdownItems(),
              onChanged: (val) {
                setState(() {
                  _selectedType = val;
                  _isCustom = val == '__CUSTOM__';
                });
              },
            ),
            const SizedBox(height: 6),

            // Custom Type Input (if Custom selected)
            if (_isCustom || _selectedType == '__CUSTOM__') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: ZenioColors.fieldFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _customTypeController,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ZenioColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter custom type (e.g. Crypto)',
                          hintStyle: TextStyle(
                            color: ZenioColors.textPlaceholder,
                            fontSize: 14,
                          ),
                          isDense: true,
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _applyCustomType(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _applyCustomType,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: ZenioColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Card Skin Selector
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: ZenioColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Card skin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ZenioColors.textSecondary,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(
                      children: List.generate(_cardImages.length, (index) {
                        final isSelected = _selectedImageIndex == index;
                        final imagePath = _cardImages[index];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImageIndex = index;
                            });
                          },
                          child: Container(
                            width: 58,
                            height: 42,
                            margin: EdgeInsets.only(
                              right: index == _cardImages.length - 1 ? 0 : 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(
                                      color: ZenioColors.primary,
                                      width: 2.5,
                                    )
                                  : Border.all(
                                      color: const Color(0xFFE5E5EA),
                                    ),
                              image: DecorationImage(
                                image: AssetImage(imagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // Save / Create Button
            Container(
              height: 55,
              margin: const EdgeInsets.only(top: 20),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onCreateWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZenioColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  widget.editingCard != null
                      ? 'Save changes'
                      : widget.isFirstWallet
                          ? 'Add Wallet & Enter Zenio'
                          : 'Create wallet',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
}
