import 'package:flutter/material.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/wallet_kind.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

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
                  // Decoded near the card's size on screen rather than
                  // at the skin's full 2166px.
                  image: ResizeImage(
                    AssetImage(card.gradientStartHex.replaceFirst('image:', '')),
                    width: 1080,
                  ),
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
                // Wallet names can be long; they end in "…" rather than
                // pushing past the card.
                Flexible(
                  child: Text(
                    card.bankName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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

            // Middle Masked Card Number, for cards only. Spaced by the column,
            // and on one line that shrinks only on narrow screens or with
            // large text.
            if (card.lastFour != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '**** **** **** ${card.lastFour}',
                maxLines: 1,
                style: AppFonts.numeric(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            // Bottom Row (Card Type & Frozen Icon)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Card types can be typed in, so they can be long too.
                Flexible(
                  child: Text(
                    card.cardType.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Fades in and out as the wallet is frozen or unfrozen.
                AnimatedSwitcher(
                  duration: ZenioMotion.of(context, ZenioMotion.fast),
                  child: isFrozen
                      ? Assets.icons.freeze.svg(
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}
