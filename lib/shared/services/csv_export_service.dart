import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/shared/services/local_database_service.dart';
import 'package:zenio/shared/utils/currency_display.dart';
import 'package:zenio/shared/utils/datetime.dart';

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  final dbService = ref.watch(localDatabaseServiceProvider);
  return CsvExportService(dbService);
});

/// Characters that make spreadsheet apps treat a cell as a formula.
const _formulaTriggers = {'=', '+', '-', '@', '\t', '\r'};

class CsvExportService {
  CsvExportService(this._dbService);

  final LocalDatabaseService _dbService;

  /// Whether [row] (as stored in the database) can be exported: its amount
  /// is a finite number, so the file never holds NaN or an infinity.
  static bool isExportable(Map<String, dynamic> row) {
    final amount = row['amount'];
    return amount is num && amount.isFinite;
  }

  /// Builds the CSV text for [transactions] (rows as stored in the database).
  /// Rows that are not [isExportable] are left out.
  static String buildCsv(List<Map<String, dynamic>> transactions) {
    final buffer = StringBuffer()
      ..writeln(
        'Date,Type,Category/Title,Amount,Currency,Wallet,Note,Transaction ID',
      );

    for (final tx in transactions.where(isExportable)) {
      final title = (tx['title'] ?? '').toString();
      final isIncome = tx['is_income'] == 1 || tx['is_income'] == true;
      final kind = resolveTransactionKind(
        kind: tx['kind'] as String?,
        title: title,
        bankName: tx['bank_name'] as String?,
        isIncome: isIncome,
      );
      final amount = tx['amount'];
      final type = switch (kind) {
        TransactionKind.expense => 'Expense',
        TransactionKind.income => 'Income',
        TransactionKind.transfer => 'Transfer',
        TransactionKind.adjustment => 'Adjustment',
      };

      final row = [
        _textCell(_exportDate(tx['date'])),
        type,
        _textCell(title),
        // An adjustment's direction is kept in the sign of its amount.
        _numberCell(
          kind == TransactionKind.adjustment && !isIncome && amount is num
              ? -amount
              : amount,
        ),
        _textCell(_exportCurrency(tx['currency'])),
        _textCell(tx['bank_name']),
        _textCell(tx['note']),
        _textCell(tx['id']),
      ];
      buffer.writeln(row.join(','));
    }
    return buffer.toString();
  }

  /// Shares all transactions as a CSV file. Returns how many were exported,
  /// and how many were left out because their stored amount is NaN or an
  /// infinity (see [isExportable]). Nothing is shared when there is
  /// nothing to export. [sharePositionOrigin] anchors the share sheet on
  /// iPad.
  Future<({int exported, int leftOut})> exportDataToCsv({
    Rect? sharePositionOrigin,
  }) async {
    final stored = await _dbService.getTransactionsMap();
    final transactions = stored.where(isExportable).toList();
    final leftOut = stored.length - transactions.length;
    if (transactions.isEmpty) return (exported: 0, leftOut: leftOut);

    final tempDir = await getTemporaryDirectory();
    // Earlier exports hold the whole history; remove them now rather than
    // right after sharing, when the receiving app may still be reading one.
    try {
      for (final old in tempDir.listSync()) {
        final name = old.uri.pathSegments.last;
        if (name.startsWith('zenio_transactions_') && name.endsWith('.csv')) {
          old.deleteSync();
        }
      }
    } catch (_) {}
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${tempDir.path}/zenio_transactions_$timestamp.csv';
    await File(filePath).writeAsString(buildCsv(transactions));

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'text/csv')],
        text: 'Zenio transactions export ($timestamp)',
        subject: 'Zenio transactions',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    return (exported: transactions.length, leftOut: leftOut);
  }

  /// A text cell that spreadsheet apps will not run as a formula: a leading
  /// trigger character is escaped with an apostrophe (removed again by the
  /// importer).
  static String _textCell(Object? value) {
    if (value == null) return '';
    var text = value.toString();
    if (text.isNotEmpty && _formulaTriggers.contains(text[0])) {
      text = "'$text";
    }
    return _quoted(text);
  }

  /// The date as dd-MM-yyyy, the format Zenio stores and imports. Older
  /// versions stored other formats, such as "Thursday, September 17, 2026";
  /// those are written as the day the app shows for them.
  static String? _exportDate(Object? stored) {
    final text = stored?.toString();
    final date = DateTimeUtils.parseTransactionDate(text);
    return date == null ? text : DateFormat('dd-MM-yyyy').format(date);
  }

  /// US dollars are stored as "DLR" but written as the standard "USD";
  /// other codes are written as stored.
  static String _exportCurrency(Object? stored) {
    final code = (stored ?? 'INR').toString();
    return currencyDisplayCode(code) == 'USD' ? 'USD' : code;
  }

  static String _numberCell(Object? value) {
    final number = value is num ? value : num.tryParse('$value');
    return number?.toString() ?? '';
  }

  static String _quoted(String text) {
    if (text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}
