import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class DebtCard extends StatelessWidget {
  const DebtCard({
    required this.debt,
    super.key,
  });

  final DebtModel debt;

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFF3F3F5),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Circle Badge with Up Arrow SVG Icon
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Assets.icons.upArrow.svg(
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF111111),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Person Name & Date Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  debt.personName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  debt.date,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9E9EA5),
                  ),
                ),
              ],
            ),
          ),

          // Amount + Currency Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatAmount(debt.amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                debt.currency,
                style: const TextStyle(
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
