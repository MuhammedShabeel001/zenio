import 'package:flutter/material.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/features/wallet/presentation/widgets/wallet_card_widget.dart';
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
                // Field 1: Wallet Id
                const Text(
                  'Wallet Id :',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9E9EA5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.cardNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
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
                            color: Color(0xFF9E9EA5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.createdAt ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),

                    // Snowflake Icon on Right Side
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2, right: 6),
                      child: Assets.icons.freeze.svg(
                        width: 28,
                        height: 28,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFD1D1D6),
                          BlendMode.srcIn,
                        ),
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
