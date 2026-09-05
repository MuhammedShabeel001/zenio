import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/shared/services/local_database_service.dart';

final csvImportServiceProvider = Provider<CsvImportService>((ref) {
  final dbService = ref.watch(localDatabaseServiceProvider);
  return CsvImportService(dbService);
});

class CsvImportService {
  CsvImportService(this._dbService);

  final LocalDatabaseService _dbService;

  /// Prompts the user to pick a .csv file and imports its records into SQLite.
  /// Returns the number of successfully imported transactions, or null if cancelled.
  Future<int?> pickAndImportCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    String csvContent;
    if (file.path != null) {
      csvContent = await File(file.path!).readAsString();
    } else if (file.bytes != null) {
      csvContent = utf8.decode(file.bytes!);
    } else {
      throw Exception('Unable to read selected file');
    }

    return importCsvContent(csvContent);
  }

  /// Parses CSV string content and saves the parsed records to the database.
  Future<int> importCsvContent(String content) async {
    final rows = parseCsv(content);
    if (rows.isEmpty) return 0;

    var dateIdx = 0;
    var typeIdx = 1;
    var titleIdx = 2;
    var amountIdx = 3;
    var currencyIdx = 4;
    var walletIdx = 5;
    var noteIdx = 6;
    var idIdx = 7;

    final firstRow = rows.first;
    var hasHeader = false;
    for (var i = 0; i < firstRow.length; i++) {
      final header = firstRow[i].toLowerCase();
      if (header.contains('date')) {
        dateIdx = i;
        hasHeader = true;
      } else if (header.contains('type')) {
        typeIdx = i;
        hasHeader = true;
      } else if (header.contains('category') || header.contains('title')) {
        titleIdx = i;
        hasHeader = true;
      } else if (header.contains('amount')) {
        amountIdx = i;
        hasHeader = true;
      } else if (header.contains('currency')) {
        currencyIdx = i;
        hasHeader = true;
      } else if (header.contains('wallet') ||
          header.contains('bank') ||
          header.contains('account')) {
        walletIdx = i;
        hasHeader = true;
      } else if (header.contains('note') || header.contains('desc')) {
        noteIdx = i;
        hasHeader = true;
      } else if (header.contains('id')) {
        idIdx = i;
        hasHeader = true;
      }
    }

    final dataRows = hasHeader ? rows.sublist(1) : rows;
    var importedCount = 0;
    final now = DateTime.now();
    final defaultTimestamp =
        '${DateFormat('yy-MM-dd').format(now)}   ${DateFormat('HH : mm').format(now)}';

    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      if (row.isEmpty) continue;

      String getVal(int idx) => idx < row.length ? row[idx].trim() : '';

      final rawAmount = getVal(amountIdx)
          .replaceAll(',', '')
          .replaceAll('₹', '')
          .replaceAll(r'$', '')
          .trim();
      final amount = double.tryParse(rawAmount) ?? 0.0;
      if (amount <= 0 && rawAmount.isEmpty) continue;

      final rawType = getVal(typeIdx).toLowerCase();
      final isIncome = rawType.contains('income') ? 1 : 0;

      var dateStr = getVal(dateIdx);
      if (dateStr.isEmpty) {
        dateStr = DateFormat('dd-MM-yyyy').format(now);
      }

      var title = getVal(titleIdx);
      if (title.isEmpty) {
        title = isIncome == 1 ? 'Income' : 'Expense';
      }

      var wallet = getVal(walletIdx);
      if (wallet.isEmpty) {
        wallet = 'Default Wallet';
      }

      var currency = getVal(currencyIdx);
      if (currency.isEmpty) {
        currency = 'INR';
      }

      final note = getVal(noteIdx);

      var id = getVal(idIdx);
      if (id.isEmpty) {
        id = '${now.millisecondsSinceEpoch}_$i';
      }

      await _dbService.saveTransactionMap({
        'id': id,
        'title': title,
        'date': dateStr,
        'amount': amount,
        'currency': currency,
        'is_income': isIncome,
        'note': note.isNotEmpty ? note : null,
        'bank_name': wallet,
        'timestamp': defaultTimestamp,
      });

      importedCount++;
    }

    return importedCount;
  }

  /// RFC 4180 compliant CSV parser that handles multiline quoted cells and escaped quotes.
  List<List<String>> parseCsv(String content) {
    final rows = <List<String>>[];
    var insideQuotes = false;
    final currentField = StringBuffer();
    var currentRow = <String>[];

    for (var i = 0; i < content.length; i++) {
      final char = content[i];

      if (char == '"') {
        if (insideQuotes && i + 1 < content.length && content[i + 1] == '"') {
          currentField.write('"');
          i++; // Skip escaped quote
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (char == ',' && !insideQuotes) {
        currentRow.add(currentField.toString().trim());
        currentField.clear();
      } else if ((char == '\n' || char == '\r') && !insideQuotes) {
        if (char == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++; // Skip \r\n
        }
        currentRow.add(currentField.toString().trim());
        currentField.clear();
        if (currentRow.any((field) => field.isNotEmpty)) {
          rows.add(currentRow);
        }
        currentRow = [];
      } else {
        currentField.write(char);
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString().trim());
      if (currentRow.any((field) => field.isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }
}
