import 'dart:convert';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/transactions/domain/models/transaction_detail_model.dart';

void main() {
  final map = {
    'id': '123',
    'title': 'Loan',
    'date': '29-08-2026',
    'amount': 234.0,
    'currency': 'INR',
    'is_income': 1,
    'note': null,
    'bank_name': 'Slice',
    'timestamp': '26-08-29   16:15'
  };

  final modMap = Map<String, dynamic>.from(map);
  modMap['is_income'] = (modMap['is_income'] as int) == 1;
  
  try {
    final tx = TransactionModel.fromJson(modMap);
    print("Home tx parsed successfully");
  } catch (e) {
    print("Home tx parse error: $e");
  }

  try {
    final tx2 = TransactionDetailModel.fromJson(modMap);
    print("Detail tx parsed successfully");
  } catch (e) {
    print("Detail tx parse error: $e");
  }
}
