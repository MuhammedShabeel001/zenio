import 'package:flutter/material.dart';
import 'package:zenio/features/wallet/domain/models/card/wallet_card_model.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class WalletCardDetailWidget extends StatelessWidget {
  const WalletCardDetailWidget({
    required this.card,
    this.isFrozen = false,
    super.key,
  });

  final WalletCardModel card;
  final bool isFrozen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Gradient Credit/Debit Card Container
          Container(
            width: double.infinity,
            height: 184,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Color(0xFF001233),
                  Color(0xFF0038A8),
                  Color(0xFF1E60D5),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x250038A8),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bank Name (SBI) & Mastercard Translucent Circles Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.bankName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
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
                                color: Colors.white.withValues(alpha: 0.3),
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
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Masked Card Number
                Text(
                  card.cardNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 2.5,
                  ),
                ),

                // Bottom Row: Card Type (DEBIT CARD) & Snowflake Freeze Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      card.cardType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.8,
                      ),
                    ),

                    // Translucent Snowflake Icon inside card
                    Assets.icons.freeze.svg(
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withValues(alpha: 0.45),
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ],
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
                const Text(
                  '1234  5678  1234  5678',
                  style: TextStyle(
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Created On :',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF9E9EA5),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'June 12 , 2026',
                          style: TextStyle(
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
