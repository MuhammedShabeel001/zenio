import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/zenio_dropdown.dart';

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
      _balanceController.text = card.balance.toStringAsFixed(2);

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
              Color(0xFF8E8E93),
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
                Color(0xFF8E8E93),
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
        labelColor: Color(0xFF10B981),
        icon: Icon(Icons.add_rounded, size: 18, color: Color(0xFF10B981)),
      ),
    );

    return items;
  }

  void _onCreateWallet() {
    var name = _nameController.text.trim();
    if (name.isEmpty) {
      if (widget.isFirstWallet) {
        name = 'Main Wallet';
      } else {
        return;
      }
    }

    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final isEditing = widget.editingCard != null;

    final r = Random();
    final p1 = (r.nextInt(9000) + 1000).toString();
    final p2 = (r.nextInt(9000) + 1000).toString();
    final p3 = (r.nextInt(9000) + 1000).toString();
    final p4 = (r.nextInt(9000) + 1000).toString();
    final cardNo = '$p1  $p2  $p3  $p4';

    final selectedImage = _cardImages[_selectedImageIndex];

    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final formattedDate = '${months[now.month - 1]} ${now.day} , ${now.year}';

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
      cardNumber: isEditing ? widget.editingCard!.cardNumber : cardNo,
      cardType: finalType,
      gradientStartHex: 'image:$selectedImage',
      gradientEndHex: 'image:$selectedImage',
      balance: isEditing ? widget.editingCard!.balance : balance,
      createdAt: isEditing ? widget.editingCard!.createdAt : formattedDate,
      isFrozen: isEditing && widget.editingCard!.isFrozen,
    );

    if (isEditing && widget.editingIndex != null) {
      ref.read(walletNotifierProvider.notifier).editCard(widget.editingIndex!, newCard);
    } else {
      ref.read(walletNotifierProvider.notifier).addCard(newCard, balance);
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {

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
                  color: const Color(0xFFD1D1D6),
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
                  color: const Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set up your starting balance and wallet name to begin.',
                style: AppFonts.text(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8E8E93),
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
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _balanceController,
                readOnly: widget.editingCard != null,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (val) {
                  if (val.length > 1 && val.startsWith('0') && !val.startsWith('0.')) {
                    final newText = val.replaceFirst(RegExp('^0+'), '');
                    _balanceController.value = TextEditingValue(
                      text: newText.isEmpty ? '0' : newText,
                      selection: TextSelection.collapsed(offset: newText.length),
                    );
                  }
                },
                style: AppFonts.numeric(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.editingCard != null ? Colors.black54 : const Color(0xFF111111),
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: AppFonts.numeric(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF9E9EA5),
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

            // Field 1: Wallet Name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111111),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Wallet name',
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
                ],
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
                  Color(0xFF8E8E93),
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
                  color: const Color(0xFFF2F2F2),
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
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Enter custom type (e.g. Crypto)',
                          hintStyle: TextStyle(
                            color: Color(0xFF9E9EA5),
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
                          color: const Color(0xFF10B981),
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
                color: const Color(0xFFF2F2F2),
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
                        color: Color(0xFF8E8E93),
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
                                      color: const Color(0xFF10B981),
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
                onPressed: _onCreateWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
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
