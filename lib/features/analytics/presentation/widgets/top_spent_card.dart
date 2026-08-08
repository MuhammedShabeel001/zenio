import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class TopSpentCard extends StatelessWidget {
  const TopSpentCard({
    required this.spend,
    super.key,
  });

  final CategorySpendModel spend;

  Widget _getIcon(String iconName) {
    switch (iconName) {
      case 'travel':
        return Assets.icons.travel.svg(
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            Color(0xFF111111),
            BlendMode.srcIn,
          ),
        );
      case 'entertainment':
        return Assets.icons.entertainment.svg(
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            Color(0xFF111111),
            BlendMode.srcIn,
          ),
        );
      case 'debt':
        return Assets.icons.debts.svg(
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            Color(0xFF111111),
            BlendMode.srcIn,
          ),
        );
      case 'expense':
        return Assets.icons.expense.svg(
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            Color(0xFF111111),
            BlendMode.srcIn,
          ),
        );
      default:
        return Assets.icons.card.svg(
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            Color(0xFF111111),
            BlendMode.srcIn,
          ),
        );
    }
  }

  Color _getBadgeBackgroundColor(String name) {
    if (name.toLowerCase().contains('travel')) {
      return const Color(0xFFFDF3E7); // Light peach/cream
    }
    if (name.toLowerCase().contains('entertainment')) {
      return const Color(0xFFF4ECFB); // Light lavender/purple
    }
    return const Color(0xFFF2F2F5);
  }

  String _formatAmount(double amount) {
    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    }
    return NumberFormat('#,##0.00').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF3F3F5), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _getBadgeBackgroundColor(spend.name),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _getIcon(spend.iconName),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  spend.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${spend.spendsCount} spends',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9E9EA5),
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '- ${_formatAmount(spend.amount)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'INR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
