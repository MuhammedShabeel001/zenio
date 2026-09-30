import 'package:flutter/material.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/features/wallet/domain/wallet_kind.dart';
import 'package:zenio/features/wallet/presentation/widgets/wallet_card_widget.dart';
import 'package:zenio/shared/shared.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
class WalletCardDetailWidget extends StatelessWidget {
  const WalletCardDetailWidget({
    required this.card,
    required this.heroTag,
    this.isFrozen = false,
    super.key,
  });

  final WalletCardModel card;
  final String heroTag;
  final bool isFrozen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Gradient Credit/Debit Card Container
          SizedBox(
            height: 184,
            width: double.infinity,
            child: Hero(
              tag: heroTag,
              child: WalletCardWidget(
                card: card,
                isFrozen: isFrozen,
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Details Section below Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Field 1: the card's last four digits, or the wallet's type
                // (only a card has a number to show).
                Text(
                  card.lastFour != null ? 'Card number :' : 'Type :',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: ZenioColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.lastFour != null ? '•••• ${card.lastFour}' : card.cardType,
                  style: AppFonts.numeric(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ZenioColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 18),

                // Field 2: Created On & Snowflake Icon on Right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Created On :',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: ZenioColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.createdAt ?? 'Unknown',
                          style: AppFonts.numeric(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: ZenioColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    // Frozen: said in words, not only by the icon.
                    if (isFrozen)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2, right: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Assets.icons.freeze.svg(
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                ZenioColors.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Frozen',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ZenioColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
