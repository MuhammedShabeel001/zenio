import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/shared/services/local_database_service.dart';

final csvImportServiceProvider = Provider<CsvImportService>((ref) {
  final dbService = ref.watch(localDatabaseServiceProvider);
  return CsvImportService(dbService);
});

class CsvImportService {
  CsvImportService(this._dbService);

  final LocalDatabaseService _dbService;

  /// Prompts the user to pick a .csv file and imports its records into SQLite.
  /// Returns null if the user cancelled. Rows without a wallet go to
  /// [defaultWallet].
  Future<CsvImportResult?> pickAndImportCsv({String? defaultWallet}) async {
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
      throw const FormatException('Unable to read selected file');
    }

    return importCsvContent(csvContent, defaultWallet: defaultWallet);
  }

  /// Column names recognised in a header row (lower case).
  static const Map<String, String> _headerColumns = {
    'date': 'date',
    'type': 'type',
    'category': 'title',
    'title': 'title',
    'category/title': 'title',
    'amount': 'amount',
    'currency': 'currency',
    'wallet': 'wallet',
    'bank': 'wallet',
    'account': 'wallet',
    'note': 'note',
    'notes': 'note',
    'description': 'note',
    'id': 'id',
    'transaction id': 'id',
  };

  /// Default column order: the order Zenio exports in.
  static const List<String> _defaultColumns = [
    'date', 'type', 'title', 'amount', 'currency', 'wallet', 'note', 'id', //
  ];

  /// Parses CSV text and saves every valid row in one database transaction.
  /// Rows whose amount or date cannot be read are skipped and counted.
  Future<CsvImportResult> importCsvContent(
    String content, {
    String? defaultWallet,
    DateTime? now,
  }) async {
    final rows = parseCsv(content);
    if (rows.isEmpty) {
      return const CsvImportResult(imported: 0, skipped: 0, alreadyPresent: 0);
    }

    // A header row is recognised by at least two known column names.
    final header = rows.first
        .map((cell) => _headerColumns[cell.trim().toLowerCase()])
        .toList();
    final hasHeader = header.whereType<String>().toSet().length >= 2;
    final columns = <String, int>{};
    if (hasHeader) {
      for (var i = 0; i < header.length; i++) {
        final column = header[i];
        if (column != null) columns.putIfAbsent(column, () => i);
      }
    } else {
      for (var i = 0; i < _defaultColumns.length; i++) {
        columns[_defaultColumns[i]] = i;
      }
    }

    final dataRows = hasHeader ? rows.sublist(1) : rows;
    final clock = now ?? DateTime.now();

    // Zenio's own export has a "Transaction ID" column whose ids are kept, so
    // re-importing an export matches the existing transactions. Ids from
    // other files are only unique within that file, so they are prefixed
    // with a fingerprint of the file; rows without an id get one from their
    // position. Importing the same file twice therefore adds nothing twice.
    final keepsZenioIds = hasHeader &&
        rows.first.any((cell) => cell.trim().toLowerCase() == 'transaction id');
    final fileKey = _fingerprint(content);
    final existingIds = {
      for (final row in await _dbService.getTransactionsMap()) row['id'],
    };
    final seenIds = <String>{};
    var alreadyPresent = 0;
    final timeOfImport = DateFormat('HH : mm').format(clock);
    // With no wallets yet, the default wallet setting is empty.
    final fallbackWallet = defaultWallet?.trim() ?? '';
    final records = <Map<String, dynamic>>[];
    var skipped = 0;

    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      String cell(String column) {
        final index = columns[column];
        if (index == null || index >= row.length) return '';
        return _unescapeText(row[index].trim());
      }

      final amount = _parseAmount(cell('amount'));
      final date = _parseDate(cell('date'));
      if (amount == null || amount == 0 || date == null) {
        skipped++;
        continue;
      }

      final type = cell('type').toLowerCase();
      final kind = switch (type) {
        'income' => TransactionKind.income,
        'transfer' => TransactionKind.transfer,
        'adjustment' => TransactionKind.adjustment,
        _ => TransactionKind.expense,
      };
      // Adjustments keep their direction in the sign of the amount.
      final isIncome = kind == TransactionKind.income ||
          (kind == TransactionKind.adjustment && amount > 0);

      var title = cell('title');
      if (title.isEmpty) {
        title = switch (kind) {
          TransactionKind.income => 'Income',
          TransactionKind.adjustment => balanceAdjustmentTitle,
          _ => 'Expense',
        };
      }

      var wallet = cell('wallet');
      if (wallet.isEmpty) {
        wallet = fallbackWallet.isEmpty ? 'Default Wallet' : fallbackWallet;
      }
      if (kind == TransactionKind.transfer &&
          parseTransferWallets(wallet) == null) {
        skipped++;
        continue;
      }

      final currency = cell('currency');
      final note = cell('note');
      final id = cell('id');

      final recordId = id.isEmpty
          ? 'csv-$fileKey-row$i'
          : (keepsZenioIds ? id : 'csv-$fileKey-$id');
      if (existingIds.contains(recordId) || !seenIds.add(recordId)) {
        alreadyPresent++;
        continue;
      }

      records.add({
        'id': recordId,
        'title': title,
        'date': DateFormat('dd-MM-yyyy').format(date),
        'amount': amount.abs(),
        'currency': currency.isEmpty ? 'INR' : currency,
        'is_income': isIncome ? 1 : 0,
        'note': note.isNotEmpty ? note : null,
        'bank_name': wallet,
        // Sorted by the transaction's own date, not the day of the import.
        'timestamp': '${DateFormat('yy-MM-dd').format(date)}   $timeOfImport',
        'kind': kind.name,
      });
    }

    // All rows are written in one database transaction: a failure part-way
    // through leaves the existing data exactly as it was.
    await _dbService.saveTransactionMaps(records);
    return CsvImportResult(
      imported: records.length,
      skipped: skipped,
      alreadyPresent: alreadyPresent,
    );
  }

  static final RegExp _number = RegExp(r'\d[\d,]*(?:\.\d+)?');

  /// Digits grouped by commas, in threes ("1,234,567") or the Indian way
  /// ("12,34,567").
  static final RegExp _groupedDigits = RegExp(r'^\d{1,3}(?:,\d{2,3})*,\d{3}$');

  /// A currency written with a dot, such as "Rs.".
  static final RegExp _currencyWithDot = RegExp(r'[A-Za-z]\.$');

  /// Reads amounts like "1,234.50", "₹ 1,234", "Rs. 500" or "-12". Returns
  /// null unless the text holds exactly one clearly written number: "12,5"
  /// or "1.234,50" are skipped rather than read as a different amount.
  static double? _parseAmount(String text) {
    final matches = _number.allMatches(text).toList();
    if (matches.length != 1) return null;
    final match = matches.single;

    // ".5" is not read as 5; a dot after letters ends a currency ("Rs.").
    final before = text.substring(0, match.start);
    if (before.endsWith('.') && !_currencyWithDot.hasMatch(before)) {
      return null;
    }

    final number = match.group(0)!;
    final wholePart = number.split('.').first;
    if (wholePart.contains(',') && !_groupedDigits.hasMatch(wholePart)) {
      return null;
    }
    final value = double.tryParse(number.replaceAll(',', ''));
    if (value == null) return null;
    return before.contains('-') ? -value : value;
  }

  /// Dates Zenio can read unambiguously: its own dd-MM-yyyy, ISO yyyy-MM-dd,
  /// dd/MM/yyyy, and the long forms older versions stored ("Thursday,
  /// September 17, 2026"). Anything else (for example the US 12/31/2025) is
  /// rejected rather than read as a different day.
  static DateTime? _parseDate(String text) {
    if (text.isEmpty) return null;
    for (final pattern in [
      'dd-MM-yyyy',
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'EEEE, MMMM d, yyyy',
      'MMMM d, yyyy',
    ]) {
      try {
        return DateFormat(pattern).parseStrict(text);
      } catch (_) {}
    }
    final iso = DateTime.tryParse(text);
    return iso == null ? null : DateTime(iso.year, iso.month, iso.day);
  }

  /// A short, stable fingerprint of [text] (FNV-1a).
  static String _fingerprint(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  /// Removes the apostrophe the exporter adds in front of text that could be
  /// read as a spreadsheet formula.
  static String _unescapeText(String text) {
    if (text.length > 1 &&
        text.startsWith("'") &&
        const {'=', '+', '-', '@', '\t', '\r'}.contains(text[1])) {
      return text.substring(1);
    }
    return text;
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

/// How an import went: rows saved, rows skipped because they could not be
/// read, and rows that were already there.
class CsvImportResult {
  const CsvImportResult({
    required this.imported,
    required this.skipped,
    required this.alreadyPresent,
  });

  final int imported;
  final int skipped;

  /// Rows that were already in Zenio (for example from importing the same
  /// file before) and were left as they are.
  final int alreadyPresent;
}
