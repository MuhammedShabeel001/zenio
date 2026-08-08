import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';

class TransactionDetailCard extends StatelessWidget {
  const TransactionDetailCard({
    required this.transaction,
    super.key,
  });

  final TransactionDetailModel transaction;

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
          // Direction Arrow Circle Badge (↓ for income, ↑ for expense)
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                transaction.isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 22,
                color: const Color(0xFF111111),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title & Date Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.date,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9E9EA5),
                  ),
                ),
              ],
            ),
          ),

          // Amount & Currency
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatAmount(transaction.amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                transaction.currency,
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
