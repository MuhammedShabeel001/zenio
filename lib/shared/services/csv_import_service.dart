import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_kind.dart';
import 'package:zenio/features/home/domain/models/transaction/transaction_model.dart';
import 'package:zenio/features/wallet/domain/wallet_balances.dart';
import 'package:zenio/shared/services/local_database_service.dart';
import 'package:zenio/shared/utils/money_limits.dart';

final csvImportServiceProvider = Provider<CsvImportService>((ref) {
  final dbService = ref.watch(localDatabaseServiceProvider);
  return CsvImportService(dbService);
});

class CsvImportService {
  CsvImportService(this._dbService);

  final LocalDatabaseService _dbService;

  /// Prompts the user to pick a .csv file and returns its text, or null if
  /// the user cancelled.
  Future<String?> pickCsvContent() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    if (file.path != null) {
      return File(file.path!).readAsString();
    } else if (file.bytes != null) {
      return utf8.decode(file.bytes!);
    }
    throw const FormatException('Unable to read selected file');
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

  /// Columns every file needs: without them a row's meaning is a guess.
  static const Map<String, String> _requiredColumns = {
    'date': 'Date',
    'type': 'Type',
    'amount': 'Amount',
    'wallet': 'Wallet',
  };

  static const Map<String, TransactionKind> _types = {
    'expense': TransactionKind.expense,
    'income': TransactionKind.income,
    'transfer': TransactionKind.transfer,
    'adjustment': TransactionKind.adjustment,
  };

  /// Reads [content] and checks every row before anything is stored.
  ///
  /// Nothing is guessed: a row whose date, type, amount or wallet is
  /// missing, unreadable or ambiguous, or that names a wallet not in
  /// [walletNames], makes the whole file fail with a [CsvImportException]
  /// saying what is wrong, so a file is imported completely or not at all.
  /// Rows already in Zenio (by transaction ID) are left out and counted.
  Future<CsvImportPlan> planImport(
    String content, {
    required Iterable<String> walletNames,
    DateTime? now,
  }) async {
    final List<List<String>> rows;
    try {
      rows = parseCsv(content);
    } on FormatException {
      throw const CsvImportException(
        "This file isn't a valid CSV file: a quoted cell is never closed.",
      );
    }
    if (rows.isEmpty) {
      return const CsvImportPlan(transactions: [], alreadyPresent: 0);
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
      final missing = [
        for (final entry in _requiredColumns.entries)
          if (!columns.containsKey(entry.key)) entry.value,
      ];
      if (missing.isNotEmpty) {
        throw CsvImportException(
          'This file has no ${_listed(missing)} '
          "column${missing.length == 1 ? '' : 's'}. Zenio needs Date, Type, "
          'Amount and Wallet columns, as in its own export.',
        );
      }
    } else {
      for (var i = 0; i < _defaultColumns.length; i++) {
        columns[_defaultColumns[i]] = i;
      }
    }

    final dataRows = hasHeader ? rows.sublist(1) : rows;
    final clock = now ?? DateTime.now();

    // Wallets by the key their names are compared by; the first wallet with
    // a name is the one its transactions count for (see wallet_balances).
    final wallets = <String, String>{};
    for (final name in walletNames) {
      wallets.putIfAbsent(walletNameKey(name), () => name);
    }

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
    final transactions = <TransactionModel>[];
    final problems = <String>[];

    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      // Numbered as a spreadsheet shows them, the header being row 1.
      final rowNumber = i + (hasHeader ? 2 : 1);
      String cell(String column) {
        final index = columns[column];
        if (index == null || index >= row.length) return '';
        return _unescapeText(row[index].trim());
      }

      final id = cell('id');
      final recordId = id.isEmpty
          ? 'csv-$fileKey-row$i'
          : (keepsZenioIds ? id : 'csv-$fileKey-$id');
      if (!seenIds.add(recordId)) {
        problems.add(
          'Row $rowNumber has the same Transaction ID as an earlier row.',
        );
        continue;
      }
      if (existingIds.contains(recordId)) {
        alreadyPresent++;
        continue;
      }

      final result = _readRow(cell, rowNumber, wallets);
      switch (result) {
        case final String problem:
          problems.add(problem);
        case final _Row read:
          transactions.add(
            TransactionModel(
              id: recordId,
              title: read.title,
              date: DateFormat('dd-MM-yyyy').format(read.date),
              amount: read.amount,
              currency: cell('currency').isEmpty ? 'INR' : cell('currency'),
              isIncome: read.isIncome,
              note: cell('note').isEmpty ? null : cell('note'),
              bankName: read.wallet,
              // Sorted by the transaction's own date, not the day of the
              // import.
              timestamp:
                  '${DateFormat('yy-MM-dd').format(read.date)}   $timeOfImport',
              kind: read.kind.name,
              transferFrom: read.transferFrom,
              transferTo: read.transferTo,
            ),
          );
      }
    }

    if (problems.isNotEmpty) {
      final more = problems.length - 1;
      throw CsvImportException(
        [
          problems.first,
          if (more > 0)
            '$more more row${more == 1 ? ' has' : 's have'} problems too.',
        ].join(' '),
      );
    }
    return CsvImportPlan(
      transactions: transactions,
      alreadyPresent: alreadyPresent,
    );
  }

  /// Reads one data row, or says what is wrong with it.
  static Object _readRow(
    String Function(String column) cell,
    int rowNumber,
    Map<String, String> wallets,
  ) {
    final dateText = cell('date');
    final date = _parseDate(dateText);
    if (date == null) {
      return dateText.isEmpty
          ? 'Row $rowNumber has no date.'
          : 'Row $rowNumber: "$dateText" isn\'t a date Zenio can read. '
              'Use DD-MM-YYYY.';
    }

    final typeText = cell('type');
    final kind = _types[typeText.toLowerCase()];
    if (kind == null) {
      return typeText.isEmpty
          ? 'Row $rowNumber has no Type. It must be Expense, Income, '
              'Transfer or Adjustment.'
          : 'Row $rowNumber: Type "$typeText" isn\'t Expense, Income, '
              'Transfer or Adjustment.';
    }

    final amountText = cell('amount');
    final amount = _parseAmount(amountText);
    if (amount == null) {
      return amountText.isEmpty
          ? 'Row $rowNumber has no amount.'
          : 'Row $rowNumber: "$amountText" isn\'t an amount Zenio can read.';
    }
    if (!isStorableAmount(amount)) {
      return 'Row $rowNumber: the amount is larger than Zenio can store.';
    }
    if (amount == 0) return 'Row $rowNumber: the amount is zero.';
    if (amount < 0 && kind != TransactionKind.adjustment) {
      return 'Row $rowNumber: only Adjustment rows can have a negative '
          'amount. Expense, Income and Transfer amounts are written without '
          'a minus sign.';
    }
    if (_decimalPlaces(amountText) > 2) {
      return 'Row $rowNumber: amounts can have at most two decimal places.';
    }

    final walletText = cell('wallet');
    if (walletText.isEmpty) return 'Row $rowNumber has no wallet.';
    final title = cell('title');

    if (kind == TransactionKind.transfer) {
      final ends = _transferWallets(walletText, title, rowNumber, wallets);
      if (ends is String) return ends;
      final (from, to) = ends as (String, String);
      return _Row(
        date: date,
        kind: kind,
        amount: roundToCents(amount),
        isIncome: false,
        title: title.isEmpty ? '$transferTitlePrefix$to' : title,
        wallet: transferBankName(from, to),
        transferFrom: from,
        transferTo: to,
      );
    }

    final wallet = wallets[walletNameKey(walletText)];
    if (wallet == null) return _noWallet(rowNumber, walletText);
    return _Row(
      date: date,
      kind: kind,
      amount: roundToCents(amount.abs()),
      // Adjustments keep their direction in the sign of the amount.
      isIncome: kind == TransactionKind.income ||
          (kind == TransactionKind.adjustment && amount > 0),
      title: title.isNotEmpty
          ? title
          : switch (kind) {
              TransactionKind.income => 'Income',
              TransactionKind.adjustment => balanceAdjustmentTitle,
              _ => 'Expense',
            },
      wallet: wallet,
    );
  }

  /// The two wallets of a transfer written "From -> To", as named in
  /// [wallets], or what is wrong. A wallet name may itself contain "->", so
  /// every way to split the text is tried; exactly one must name two
  /// existing wallets (the title "Transfer to X" settles a tie).
  static Object _transferWallets(
    String text,
    String title,
    int rowNumber,
    Map<String, String> wallets,
  ) {
    final splits = transferSplits(text);
    if (splits.isEmpty) {
      return "Row $rowNumber: a transfer's wallet must be written as "
          '"From -> To".';
    }
    var matching = [
      for (final split in splits)
        if (wallets.containsKey(walletNameKey(split.from)) &&
            wallets.containsKey(walletNameKey(split.to)))
          split,
    ];
    if (matching.length > 1 && title.startsWith(transferTitlePrefix)) {
      final destination =
          walletNameKey(title.substring(transferTitlePrefix.length));
      matching = [
        for (final split in matching)
          if (walletNameKey(split.to) == destination) split,
      ];
    }
    if (matching.length > 1) {
      return 'Row $rowNumber: the transfer "$text" can be read as between '
          "different wallets; Zenio can't tell which.";
    }
    if (matching.isEmpty) {
      if (splits.length == 1) {
        final split = splits.single;
        final missing = wallets.containsKey(walletNameKey(split.from))
            ? split.to
            : split.from;
        return _noWallet(rowNumber, missing);
      }
      return 'Row $rowNumber: Zenio has no two wallets that the transfer '
          '"$text" is between. Add them first, then import again.';
    }
    final from = wallets[walletNameKey(matching.single.from)]!;
    final to = wallets[walletNameKey(matching.single.to)]!;
    if (walletNameKey(from) == walletNameKey(to)) {
      return 'Row $rowNumber: a transfer needs two different wallets.';
    }
    return (from, to);
  }

  /// Digits after the decimal point of the one number in [text], as written
  /// (counting them is exact, unlike checking the parsed value).
  static int _decimalPlaces(String text) {
    final number = _number.firstMatch(text)?.group(0) ?? '';
    final point = number.indexOf('.');
    return point == -1 ? 0 : number.length - point - 1;
  }

  static String _noWallet(int rowNumber, String name) =>
      "Row $rowNumber: there's no wallet named \"$name\" in Zenio. Add it "
      'first, with its current balance, then import again.';

  static String _listed(List<String> items) => items.length == 1
      ? items.single
      : '${items.sublist(0, items.length - 1).join(', ')} or ${items.last}';

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

  /// RFC 4180 compliant CSV parser that handles multiline quoted cells and
  /// escaped quotes. Throws a [FormatException] if a quoted cell is never
  /// closed.
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

    // Otherwise the rest of the file would silently become one cell.
    if (insideQuotes) {
      throw const FormatException('A quoted cell is never closed.');
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

/// A checked file, ready to be imported (see
/// `WalletNotifier.importTransactions`).
class CsvImportPlan {
  const CsvImportPlan({
    required this.transactions,
    required this.alreadyPresent,
  });

  /// The transactions to add, every one of them valid.
  final List<TransactionModel> transactions;

  /// Rows that were already in Zenio (for example from importing the same
  /// file before) and are left as they are.
  final int alreadyPresent;
}

/// A file that cannot be imported safely, with a message for the user.
/// Nothing has been stored.
class CsvImportException implements Exception {
  const CsvImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One valid data row.
class _Row {
  const _Row({
    required this.date,
    required this.kind,
    required this.amount,
    required this.isIncome,
    required this.title,
    required this.wallet,
    this.transferFrom,
    this.transferTo,
  });

  final DateTime date;
  final TransactionKind kind;
  final double amount;
  final bool isIncome;
  final String title;
  final String wallet;
  final String? transferFrom;
  final String? transferTo;
}
