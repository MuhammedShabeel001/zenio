import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/wallet_kind.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/utils/formatters.dart';
import 'package:zenio/shared/widgets/money.dart';
import 'package:zenio/shared/widgets/zenio_dropdown.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

class EditWalletDialog extends ConsumerStatefulWidget {
  const EditWalletDialog({
    required this.card,
    required this.cardIndex,
    super.key,
  });

  final WalletCardModel card;
  final int cardIndex;

  static Future<void> show(
    BuildContext context, {
    required WalletCardModel card,
    required int cardIndex,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => EditWalletDialog(
        card: card,
        cardIndex: cardIndex,
      ),
    );
  }

  @override
  ConsumerState<EditWalletDialog> createState() => _EditWalletDialogState();
}

class _EditWalletDialogState extends ConsumerState<EditWalletDialog> {
  late TextEditingController _nameController;
  late TextEditingController _cardNumberController;
  late TextEditingController _balanceController;
  late TextEditingController _customTypeController;
  late String _selectedType;
  bool _isCustom = false;
  final List<String> _customTypes = [];
  int _selectedImageIndex = 0;

  static const List<Map<String, String>> _presetTypes = [
    {'value': 'BANK', 'label': 'Bank'},
    {'value': 'DEBIT CARD', 'label': 'Debit'},
    {'value': creditCardWalletType, 'label': 'Credit'},
    {'value': 'CASH', 'label': 'Cash'},
    {'value': 'SAVINGS', 'label': 'Savings'},
  ];

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
    final card = widget.card;
    _nameController = TextEditingController(text: card.bankName);
    // Only a card's last four digits are shown, never a full number.
    _cardNumberController = TextEditingController(text: card.lastFour ?? '');
    _customTypeController = TextEditingController();
    
    final balance = card.balance;
    _balanceController = TextEditingController(
      text: AppNumberFormat.formatAmount(balance),
    );

    // Load custom types from existing cards
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

    final cardUpper = card.cardType.toUpperCase();
    final matchPreset = _presetTypes.firstWhere(
      (p) =>
          p['value'] == cardUpper ||
          (cardUpper == 'DEBIT' && p['value'] == 'DEBIT CARD') ||
          (cardUpper == 'CREDIT' && p['value'] == 'CREDIT CARD'),
      orElse: () => {},
    );
    if (matchPreset.isNotEmpty) {
      _selectedType = matchPreset['value']!;
    } else {
      if (!_customTypes.contains(card.cardType)) {
        _customTypes.add(card.cardType);
      }
      _selectedType = card.cardType;
      _customTypeController.text = card.cardType;
    }

    final imgPath = card.gradientStartHex.startsWith('image:')
        ? card.gradientStartHex.substring(6)
        : card.gradientStartHex;
    final index = _cardImages.indexOf(imgPath);
    if (index != -1) {
      _selectedImageIndex = index;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cardNumberController.dispose();
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

  /// The balance typed in, or null when the field is empty (left as it is)
  /// or not an amount.
  double? get _enteredBalance {
    final text = _balanceController.text.trim();
    if (text.isEmpty || text == '-') return null;
    return AppNumberFormat.tryParseAmount(text);
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter a wallet name');
      return;
    }
    final notifier = ref.read(walletNotifierProvider.notifier);
    if (notifier.isNameTaken(name, exceptId: widget.card.id)) {
      setState(() => _nameError = 'You already have a wallet with this name');
      return;
    }

    // An empty balance leaves it as it is rather than setting it to zero.
    final balance = _enteredBalance ?? widget.card.balance;
    // The stored number changes only when the digits were changed here.
    final lastFour = _cardNumberController.text.trim();
    final cardNumber =
        lastFour.isNotEmpty && lastFour != (widget.card.lastFour ?? '')
            ? lastFour
            : widget.card.cardNumber;

    final selectedImage = _cardImages[_selectedImageIndex];

    var finalType = _selectedType;
    if (_selectedType == '__CUSTOM__' || _isCustom) {
      final customText = _customTypeController.text.trim();
      if (customText.isNotEmpty) {
        finalType = customText;
      } else {
        finalType = 'CUSTOM';
      }
    }

    final updatedCard = widget.card.copyWith(
      bankName: name,
      cardNumber: cardNumber,
      cardType: finalType,
      gradientStartHex: 'image:$selectedImage',
      gradientEndHex: 'image:$selectedImage',
    );

    setState(() {
      _isSaving = true;
      _nameError = null;
    });
    final adjusts = balance != widget.card.balance;
    var detailsSaved = false;
    try {
      await notifier.editCard(widget.cardIndex, updatedCard);
      detailsSaved = true;
      // A different balance is recorded as an adjustment, so the change is
      // visible in the history instead of silently overwriting it.
      if (adjusts) {
        await notifier.adjustBalance(widget.card.id, balance);
      }
    } catch (e) {
      if (!mounted) return;
      // Shown in the dialog: a snackbar would appear behind its barrier.
      setState(() {
        _isSaving = false;
        _nameError = e is WalletNameConflictException
            ? e.message
            : detailsSaved
                ? "The wallet was saved, but its balance couldn't be "
                    'changed. Please try again.'
                : "Couldn't save the wallet. Please try again.";
      });
      return;
    }
    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    ZenioSnackBar.show(
      context,
      message: adjusts
          ? 'Wallet saved · balance is now '
              '${Money.balance(balance, symbol: ref.read(currencySymbolProvider))}'
          : 'Wallet saved',
      type: ZenioSnackBarType.success,
    );
    Navigator.of(context).pop();
  }


  /// Whether the chosen type is a card, which has digits to show.
  bool get _typeIsCard {
    final type = _selectedType == '__CUSTOM__' || _isCustom
        ? _customTypeController.text
        : _selectedType;
    return type.toUpperCase().contains('CARD');
  }

  /// Says what saving a different balance does, before it is saved.
  Widget _adjustmentNote(String currencySymbol) {
    final entered = _enteredBalance;
    if (entered == null) return const SizedBox(width: double.infinity);
    final delta = entered - widget.card.balance;
    if (delta.abs() < 0.005) return const SizedBox(width: double.infinity);
    final change = Money.signed(
      delta,
      symbol: currencySymbol,
      direction: delta > 0 ? MoneyDirection.incoming : MoneyDirection.outgoing,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      child: Text(
        'Saving records a balance adjustment of $change. '
        "It isn't income or spending.",
        style: const TextStyle(
          fontSize: 13,
          height: 1.35,
          color: ZenioColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
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
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit wallet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ZenioColors.textPrimary,
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
              const SizedBox(height: 18),

              // Balance: changing it records an adjustment, said below.
              const Padding(
                padding: EdgeInsets.only(left: 14, bottom: 6),
                child: Text(
                  'Current balance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: ZenioColors.textSecondary,
                  ),
                ),
              ),
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
                        color: ZenioColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          // A balance can be below zero, e.g. a credit card.
                          ThousandsSeparatorInputFormatter(allowNegative: true),
                        ],
                        onChanged: (val) {
                          setState(() {});
                        },
                        style: AppFonts.numeric(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ZenioColors.textPrimary,
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
              AnimatedSize(
                duration: ZenioMotion.of(context, ZenioMotion.standard),
                curve: ZenioMotion.standardCurve,
                alignment: Alignment.topCenter,
                child: _adjustmentNote(currencySymbol),
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
                        textInputAction: TextInputAction.next,
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

              // Field 3: a card's last four digits (other wallets have none)
              if (_typeIsCard)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: ZenioColors.fieldFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Assets.icons.card.svg(
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
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        style: AppFonts.numeric(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ZenioColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Last 4 digits (optional)',
                          hintStyle: AppFonts.numeric(
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
              if (_typeIsCard) const SizedBox(height: 6),

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

                          return Semantics(
                            button: true,
                            selected: isSelected,
                            label: 'Card design ${index + 1}',
                            child: GestureDetector(
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
                                  // Decoded at thumbnail size, not the full 2166px skin.
                                  image: ResizeImage(AssetImage(imagePath), width: 180),
                                  fit: BoxFit.cover,
                                ),
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

              // Save Changes Button
              Container(
                height: 55,
                margin: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZenioColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Save changes',
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
      ),
    );
  }
}
