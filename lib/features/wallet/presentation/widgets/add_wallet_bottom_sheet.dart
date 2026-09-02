import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/wallet/controller/wallet/wallet_notifier.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class AddWalletBottomSheet extends ConsumerStatefulWidget {
  const AddWalletBottomSheet({
    this.editingCard,
    this.editingIndex,
    super.key,
  });

  final WalletCardModel? editingCard;
  final int? editingIndex;

  static void show(BuildContext context, {WalletCardModel? editingCard, int? editingIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddWalletBottomSheet(
        editingCard: editingCard,
        editingIndex: editingIndex,
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
  String _selectedType = 'DEBIT CARD';
  int _selectedImageIndex = 0;

  final List<String> _walletTypes = ['DEBIT CARD', 'CREDIT CARD', 'PREPAID'];

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
    if (widget.editingCard != null) {
      final card = widget.editingCard!;
      _nameController.text = card.bankName;
      _balanceController.text = card.balance.toStringAsFixed(2);
      if (_walletTypes.contains(card.cardType)) {
        _selectedType = card.cardType;
      }
      
      String imgPath = card.gradientStartHex;
      if (imgPath.startsWith('image:')) {
        imgPath = imgPath.substring(6);
      }
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
    super.dispose();
  }

  void _onCreateWallet() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

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
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final formattedDate = '${months[now.month - 1]} ${now.day} , ${now.year}';

    final newCard = WalletCardModel(
      id: isEditing ? widget.editingCard!.id : DateTime.now().toIso8601String(),
      bankName: name,
      cardNumber: isEditing ? widget.editingCard!.cardNumber : cardNo,
      cardType: _selectedType,
      gradientStartHex: 'image:$selectedImage',
      gradientEndHex: 'image:$selectedImage',
      balance: isEditing ? widget.editingCard!.balance : balance,
      createdAt: isEditing ? widget.editingCard!.createdAt : formattedDate,
      isFrozen: isEditing ? widget.editingCard!.isFrozen : false,
    );

    if (isEditing && widget.editingIndex != null) {
      ref.read(walletNotifierProvider.notifier).editCard(widget.editingIndex!, newCard);
    } else {
      ref.read(walletNotifierProvider.notifier).addCard(newCard, balance);
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: bottomInset > 0 ? bottomInset + 20 : 40,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Wallet Name TextField
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Wallet name',
                  hintStyle: TextStyle(
                    color: Color(0xFFA0A0A0),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Wallet Type Dropdown
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: Colors.white,
                  items: _walletTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedType = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Initial Balance
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _balanceController,
                readOnly: widget.editingCard != null,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.editingCard != null ? Colors.black54 : Colors.black,
                ),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    color: Color(0xFFA0A0A0),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Image Pickers
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
                      width: 56,
                      height: 40,
                      margin: EdgeInsets.only(right: index == _cardImages.length - 1 ? 0 : 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: const Color(0xFF10B981), width: 3)
                            : Border.all(color: Colors.transparent, width: 3),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                        ],
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
            const SizedBox(height: 32),

            // Create wallet / Save changes button
            ElevatedButton(
              onPressed: _onCreateWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.editingCard != null ? 'Save changes' : 'Create wallet',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
