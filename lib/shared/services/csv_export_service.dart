import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenio/shared/services/local_database_service.dart';

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  final dbService = ref.watch(localDatabaseServiceProvider);
  return CsvExportService(dbService);
});

class CsvExportService {
  CsvExportService(this._dbService);

  final LocalDatabaseService _dbService;

  Future<void> exportDataToCsv() async {
    final transactions = await _dbService.getTransactionsMap();

    final buffer = StringBuffer()
      ..writeln('Date,Type,Category/Title,Amount,Currency,Wallet,Note,Transaction ID');

    for (final tx in transactions) {
      final date = tx['date'] ?? '';
      final title = tx['title'] ?? '';
      final isIncome = tx['is_income'] == 1 || tx['is_income'] == true;
      final amount = tx['amount'] ?? 0;
      final currency = tx['currency'] ?? 'INR';
      final wallet = tx['bank_name'] ?? '';
      final note = tx['note'] ?? '';
      final id = tx['id'] ?? '';

      String type;
      if (title.toString().toLowerCase().startsWith('transfer')) {
        type = 'Transfer';
      } else if (isIncome) {
        type = 'Income';
      } else {
        type = 'Expense';
      }

      final row = [
        _escapeCsv(date),
        _escapeCsv(type),
        _escapeCsv(title),
        _escapeCsv(amount),
        _escapeCsv(currency),
        _escapeCsv(wallet),
        _escapeCsv(note),
        _escapeCsv(id),
      ];
      buffer.writeln(row.join(','));
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${tempDir.path}/zenio_transactions_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    final xFile = XFile(filePath, mimeType: 'text/csv');
    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: 'Zenio Financial Data Export ($timestamp)',
        subject: 'Zenio CSV Export',
      ),
    );
  }

  String _escapeCsv(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }
}
