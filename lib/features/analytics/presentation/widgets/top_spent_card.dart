import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class TopSpentCard extends StatefulWidget {
  const TopSpentCard({
    required this.spend,
    this.isExpanded,
    this.onTap,
    super.key,
  });

  final CategorySpendModel spend;
  final bool? isExpanded;
  final VoidCallback? onTap;

  @override
  State<TopSpentCard> createState() => _TopSpentCardState();
}

class _TopSpentCardState extends State<TopSpentCard> {
  bool _internalExpanded = false;

  bool get _effectiveIsExpanded => widget.isExpanded ?? _internalExpanded;

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

  double _getSpendRatio(CategorySpendModel spend) {
    if (spend.amount >= 1200) return 0.65;
    if (spend.amount >= 1000) return 0.55;
    if (spend.amount >= 800) return 0.45;
    if (spend.amount >= 500) return 0.35;
    return 0.25;
  }

  String _formatAmount(double amount) {
    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    }
    return NumberFormat('#,##0.00').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.spend);
    final ratio = _getSpendRatio(widget.spend);

    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          setState(() {
            _internalExpanded = !_internalExpanded;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF3F3F5), width: 1.2),
          boxShadow: _effectiveIsExpanded
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _getBadgeBackgroundColor(widget.spend.name),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _getIcon(widget.spend.iconName),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.spend.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.spend.spendsCount} spends',
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
                      '- ${_formatAmount(widget.spend.amount)}',
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

            // Expandable Progress Bar Section
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstCurve: Curves.fastOutSlowIn,
              secondCurve: Curves.fastOutSlowIn,
              crossFadeState: _effectiveIsExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECECEC),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
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
