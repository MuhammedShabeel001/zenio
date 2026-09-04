import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';
import 'package:zenio/features/subscriptions/controller/categories/subscription_categories_notifier.dart';
import 'package:zenio/features/transactions/controller/categories/categories_notifier.dart';

class TopSpentCard extends ConsumerWidget {
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

  bool _isEmoji(String text) {
    if (text.isEmpty) return false;
    return text.runes.any((rune) => rune > 255 || (rune >= 0x2000 && rune <= 0x3299));
  }

  String _getCategoryEmoji(WidgetRef ref, CategorySpendModel spend) {
    final categories = ref.watch(categoriesNotifierProvider);
    final cleanName = spend.name.trim().toLowerCase();

    // 1. Exact match in saved categories
    final exactMatch = categories.where(
      (c) => c.name.trim().toLowerCase() == cleanName,
    );
    if (exactMatch.isNotEmpty && exactMatch.first.emoji.trim().isNotEmpty) {
      return exactMatch.first.emoji.trim();
    }

    // 2. Exact match in subscription categories
    final subCategories = ref.watch(subscriptionCategoriesNotifierProvider);
    final subMatch = subCategories.where(
      (c) => c.name.trim().toLowerCase() == cleanName,
    );
    if (subMatch.isNotEmpty && subMatch.first.emoji.trim().isNotEmpty) {
      return subMatch.first.emoji.trim();
    }

    // 3. If spend.iconName is already an emoji, use it
    if (_isEmoji(spend.iconName)) {
      return spend.iconName;
    }

    // 4. Fuzzy / Contains match in saved categories
    final fuzzyMatch = categories.where(
      (c) =>
          cleanName.contains(c.name.trim().toLowerCase()) ||
          c.name.trim().toLowerCase().contains(cleanName),
    );
    if (fuzzyMatch.isNotEmpty && fuzzyMatch.first.emoji.trim().isNotEmpty) {
      return fuzzyMatch.first.emoji.trim();
    }

    // 5. Default keyword fallbacks
    if (cleanName.contains('food') || cleanName.contains('drink') || cleanName.contains('dine') || cleanName.contains('restaurant') || cleanName.contains('cafe')) {
      return '🍔';
    }
    if (cleanName.contains('travel') || cleanName.contains('trip') || cleanName.contains('transport') || cleanName.contains('fuel') || cleanName.contains('flight') || cleanName.contains('cab')) {
      return '🚗';
    }
    if (cleanName.contains('shopping') || cleanName.contains('shop') || cleanName.contains('clothes') || cleanName.contains('store')) {
      return '🛍️';
    }
    if (cleanName.contains('entertainment') || cleanName.contains('movie') || cleanName.contains('cinema') || cleanName.contains('music') || cleanName.contains('game')) {
      return '🎬';
    }
    if (cleanName.contains('bills') || cleanName.contains('bill') || cleanName.contains('utility') || cleanName.contains('electricity')) {
      return '💡';
    }
    if (cleanName.contains('loan') || cleanName.contains('debt')) {
      return '💳';
    }
    if (cleanName.contains('grocery') || cleanName.contains('market')) {
      return '🛒';
    }
    if (cleanName.contains('health') || cleanName.contains('medical') || cleanName.contains('doctor') || cleanName.contains('pharmacy')) {
      return '💊';
    }
    if (cleanName.contains('school') || cleanName.contains('education') || cleanName.contains('college')) {
      return '🎓';
    }

    return '🏷️';
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
        var clean = spend.colorHex.replaceAll('#', '').trim();
        if (clean.startsWith('0x') || clean.startsWith('0X')) {
          return Color(int.parse(clean));
        }
        if (clean.length == 6) {
          clean = 'FF$clean';
        }
        return Color(int.parse('0x$clean'));
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
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = _getCategoryColor(spend);
    final ratio = _getSpendRatio(spend, totalSpend);
    final expanded = isExpanded ?? false;
    final emoji = _getCategoryEmoji(ref, spend);

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
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
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
              sizeCurve: Curves.fastOutSlowIn,
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(
                width: double.infinity,
                height: 0,
              ),
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
