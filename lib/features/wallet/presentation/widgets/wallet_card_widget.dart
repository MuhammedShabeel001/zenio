import 'package:flutter/material.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';

class WalletCardWidget extends StatelessWidget {
  const WalletCardWidget({
    required this.card,
    this.isFrozen = false,
    this.onTap,
    super.key,
  });

  final WalletCardModel card;
  final bool isFrozen;
  final VoidCallback? onTap;

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex));
    } catch (_) {
      return const Color(0xFF031B4E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startColor = _parseColor(card.gradientStartHex);
    final endColor = _parseColor(card.gradientEndHex);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
        padding: const EdgeInsets.all(33),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: card.gradientStartHex.startsWith('image:')
              ? DecorationImage(
                  image: AssetImage(card.gradientStartHex.replaceFirst('image:', '')),
                  fit: BoxFit.cover,
                )
              : null,
          gradient: card.gradientStartHex.startsWith('image:')
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [startColor, endColor],
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row (Bank Name & Dual Overlapping Circles)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.bankName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                // Mastercard-style overlapping translucent circles
                SizedBox(
                  width: 48,
                  height: 32,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Middle Masked Card Number
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                isFrozen ? '****  FROZEN  ****' : '**** **** **** ${card.cardNumber.length >= 4 ? card.cardNumber.substring(card.cardNumber.length - 4) : card.cardNumber}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // Bottom Card Type
            Text(
              card.cardType.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
