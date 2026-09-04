import 'package:flutter/material.dart';
import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';

class CategoryLegendWidget extends StatelessWidget {
  const CategoryLegendWidget({
    required this.categories,
    super.key,
  });

  final List<CategorySpendModel> categories;

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex));
    } catch (_) {
      return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 16,
      children: categories.map((item) {
        final color = _parseColor(item.colorHex);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
