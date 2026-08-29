import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/shared/services/local_database_service.dart';

void main() async {
  final dbService = LocalDatabaseService();
  final maps = await dbService.getTransactionsMap();
  print("Maps: $maps");
  if (maps.isNotEmpty) {
    try {
      final txs = maps.map((map) {
        final modMap = Map<String, dynamic>.from(map);
        modMap['is_income'] = (modMap['is_income'] as int) == 1;
        return TransactionModel.fromJson(modMap);
      }).toList();
      print("Parsed successfully: ${txs.length}");
    } catch (e, stack) {
      print("Error parsing: $e");
      print(stack);
    }
  } else {
    print("No maps");
  }
}
