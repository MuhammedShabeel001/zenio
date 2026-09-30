import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/formatters.dart';

/// Whether an amount adds to the user's money, takes from it, or neither
/// (a transfer between their own wallets).
enum MoneyDirection { incoming, outgoing, neutral }

/// How amounts are written everywhere: the sign first, then the currency
/// symbol, then the number ("+₹85,000", "−₹420", "₹2,000").
abstract final class Money {
  /// A true minus sign, which screen readers read as "minus".
  static const String minus = '−';

  /// [amount] (its size only) with the sign for [direction].
  static String signed(
    double amount, {
    required String symbol,
    required MoneyDirection direction,
    bool alwaysShowDecimals = false,
  }) {
    // Rounded to the cent first, so 0.001 reads "0", not "0.00".
    final cents = (amount.abs() * 100).round();
    final value = AppNumberFormat.formatAmount(
      cents / 100,
      alwaysShowDecimals: alwaysShowDecimals,
    );
    // Nothing that shows as zero gets a sign.
    final isZero = cents == 0;
    final sign = isZero
        ? ''
        : switch (direction) {
            MoneyDirection.incoming => '+',
            MoneyDirection.outgoing => minus,
            MoneyDirection.neutral => '',
          };
    return '$sign$symbol$value';
  }

  /// A balance that may be below zero: "₹12,400" or "−₹12,400".
  static String balance(
    double amount, {
    required String symbol,
    bool alwaysShowDecimals = false,
  }) {
    return signed(
      amount,
      symbol: symbol,
      direction: amount < 0 ? MoneyDirection.outgoing : MoneyDirection.neutral,
      alwaysShowDecimals: alwaysShowDecimals,
    );
  }

  /// Money coming in is green; everything else keeps the text colour, so
  /// the sign, not the colour, carries the meaning.
  static Color colorFor(MoneyDirection direction) =>
      direction == MoneyDirection.incoming
          ? ZenioColors.income
          : ZenioColors.textPrimary;
}

/// An amount in a list row, signed and coloured by [direction].
class AmountText extends ConsumerWidget {
  const AmountText(
    this.amount, {
    required this.direction,
    this.fontSize = ZenioFontSizes.bodyLarge,
    this.color,
    super.key,
  });

  final double amount;
  final MoneyDirection direction;
  final double fontSize;

  /// Overrides the colour for [direction].
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      Money.signed(
        amount,
        symbol: ref.watch(currencySymbolProvider),
        direction: direction,
      ),
      maxLines: 1,
      style: AppFonts.numeric(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color ?? Money.colorFor(direction),
      ),
    );
  }
}

/// The large amount at the top of a screen, with a caption saying what it
/// is ("Total balance", "Spent · September"). Shrinks to fit rather than
/// overflowing.
class HeadlineAmount extends ConsumerWidget {
  const HeadlineAmount({
    required this.amount,
    required this.caption,
    this.approximate = false,
    super.key,
  });

  /// May be below zero, e.g. a credit card balance.
  final double amount;

  final String caption;

  /// Prefixes "≈", for estimates such as a monthly equivalent.
  final bool approximate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(currencySymbolProvider);
    final large = AppFonts.numeric(
      fontSize: ZenioFontSizes.display,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: -0.5,
    );
    final prefix = [
      if (approximate) '≈ ',
      if ((amount * 100).round() < 0) Money.minus,
      symbol,
      ' ',
    ].join();
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: prefix),
                TextSpan(
                  text: AppNumberFormat.formatNumber(
                    (amount.abs() * 100).round() ~/ 100,
                  ),
                ),
                TextSpan(
                  text: AppNumberFormat.formatDecimalPart(amount.abs()),
                  style: AppFonts.numeric(
                    fontSize: ZenioFontSizes.amount,
                    fontWeight: FontWeight.bold,
                    color: ZenioColors.textOnDarkSecondary,
                  ),
                ),
              ],
            ),
            style: large,
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(
              fontSize: ZenioFontSizes.body,
              fontWeight: FontWeight.w400,
              color: ZenioColors.textOnDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
