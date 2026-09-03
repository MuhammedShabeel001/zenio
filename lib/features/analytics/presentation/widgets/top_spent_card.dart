import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class TopSpentCard extends StatelessWidget {
  const TopSpentCard({
    required this.spend,
    this.totalSpend,
    this.isExpanded,
    this.onTap,
    super.key,
  });

  final CategorySpendModel spend;
  final double? totalSpend;
  final bool? isExpanded;
  final VoidCallback? onTap;

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
    final lower = name.toLowerCase();
    if (lower.contains('travel')) {
      return const Color(0xFFFDF3E7); // Light peach/cream
    }
    if (lower.contains('entertainment')) {
      return const Color(0xFFF4ECFB); // Light lavender/purple
    }
    if (lower.contains('loan') || lower.contains('debt')) {
      return const Color(0xFFE8F8F0); // Light mint/green
    }
    if (lower.contains('food')) {
      return const Color(0xFFFFEAEA); // Light red
    }
    if (lower.contains('shop')) {
      return const Color(0xFFE6F3FF); // Light blue
    }
    return const Color(0xFFF2F2F5);
  }

  Color _getCategoryColor(CategorySpendModel spend) {
    if (spend.colorHex.isNotEmpty) {
      try {
        final hex = spend.colorHex.replaceAll('#', '');
        return Color(int.parse('0xFF$hex'));
      } catch (_) {}
    }
    final lower = spend.name.toLowerCase();
    if (lower.contains('travel')) return const Color(0xFFFF7A00);
    if (lower.contains('entertainment')) return const Color(0xFF8B5CF6);
    if (lower.contains('loan') || lower.contains('debt')) {
      return const Color(0xFF10B981);
    }
    if (lower.contains('food')) return const Color(0xFFEF4444);
    if (lower.contains('shop')) return const Color(0xFF3B82F6);
    return const Color(0xFF06B6D4);
  }

  double _getSpendRatio(CategorySpendModel spend, double? totalSpend) {
    if (totalSpend != null && totalSpend > 0) {
      return (spend.amount / totalSpend).clamp(0.0, 1.0);
    }
    return 0;
  }

  String _formatAmount(double amount) {
    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    }
    return NumberFormat('#,##0.00').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(spend);
    final ratio = _getSpendRatio(spend, totalSpend);
    final expanded = isExpanded ?? false;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.fromLTRB(5, 5, 20, 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getBadgeBackgroundColor(spend.name),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _getIcon(spend.iconName),
                  ),
                ),
                const SizedBox(width: 17),
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

            // Tap-to-Expand Animated Progress Bar Section
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstCurve: Curves.fastOutSlowIn,
              secondCurve: Curves.fastOutSlowIn,
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(15, 15, 0, 10),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECECEC),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: expanded ? ratio : 0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedRatio, child) {
                        return FractionallySizedBox(
                          widthFactor: animatedRatio.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: categoryColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
