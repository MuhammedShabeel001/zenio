import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/shared/services/csv_export_service.dart';
import 'package:zenio/shared/services/csv_import_service.dart';

import '../../helpers/test_storage.dart';

void main() {
  final now = DateTime(2026, 9, 30, 10, 15);

  group('export', () {
    test('escapes cells that spreadsheets would run as formulas', () {
      final csv = CsvExportService.buildCsv([
        {
          'id': '1',
          'title': '=HYPERLINK("http://evil")',
          'date': '01-09-2026',
          'amount': 10.5,
          'currency': 'INR',
          'is_income': 0,
          'bank_name': '@Wallet',
          'note': '+note, with comma',
        },
      ]);

      final row = csv.trim().split('\n').last;
      expect(row, contains('"\'=HYPERLINK(""http://evil"")"'));
      expect(row, contains("'@Wallet"));
      expect(row, contains('"\'+note, with comma"'));
      expect(row, contains(',10.5,'));
    });

    test('labels transfers and keeps the direction of adjustments', () {
      final csv = CsvExportService.buildCsv([
        {
          'id': 't',
          'title': 'Transfer to Cash',
          'date': '01-09-2026',
          'amount': 5,
          'currency': 'INR',
          'is_income': 0,
          'bank_name': 'HDFC -> Cash',
        },
        {
          'id': 'a',
          'title': 'Balance adjustment',
          'date': '01-09-2026',
          'amount': 7,
          'currency': 'INR',
          'is_income': 0,
          'bank_name': 'HDFC',
          'kind': 'adjustment',
        },
      ]);

      expect(csv, contains('01-09-2026,Transfer,Transfer to Cash,5,'));
      expect(csv, contains('01-09-2026,Adjustment,Balance adjustment,-7,'));
    });
  });

  group('import', () {
    test('skips rows it cannot read instead of guessing', () async {
      final storage = TestStorage.create();
      final service = CsvImportService(storage.open());

      final result = await service.importCsvContent(
        'Date,Type,Category/Title,Amount,Wallet\n'
        '15-09-2026,Expense,Food,120,HDFC\n'
        '12/31/2025,Expense,US date,50,HDFC\n'
        '16-09-2026,Expense,No amount,abc,HDFC\n'
        '17-09-2026,Income,Salary,"1,000.50",\n',
        defaultWallet: 'Cash',
        now: now,
      );

      expect(result.imported, 2);
      expect(result.skipped, 2);
      final rows = await storage.transactionRows();
      final salary = rows.firstWhere((r) => r['title'] == 'Salary');
      expect(salary['amount'], 1000.5);
      expect(salary['is_income'], 1);
      expect(salary['bank_name'], 'Cash');
      // Sorted by its own date rather than the day it was imported.
      expect(salary['timestamp'], '26-09-17   10 : 15');
    });

    test('reads a first row of data as data', () async {
      final storage = TestStorage.create();
      final service = CsvImportService(storage.open());

      // "Candidate" contains "date" but is not a header.
      final result = await service.importCsvContent(
        '15-09-2026,Expense,Candidate fee,99,HDFC\n',
        now: now,
      );

      expect(result.imported, 1);
      final row = (await storage.transactionRows()).single;
      expect(row['title'], 'Candidate fee');
      expect(row['amount'], 99);
    });

    test('importing the same file twice adds nothing the second time',
        () async {
      final storage = TestStorage.create();
      final service = CsvImportService(storage.open());
      const file = 'Date,Category,Amount,Wallet\n'
          '15-09-2026,Food,120,HDFC\n'
          '16-09-2026,Taxi,80,HDFC\n';

      final first = await service.importCsvContent(file, now: now);
      final second = await service.importCsvContent(file, now: now);

      expect(first.imported, 2);
      expect(second.imported, 0);
      expect(second.alreadyPresent, 2);
      expect(await storage.transactionRows(), hasLength(2));
    });

    test('files with the same row ids do not overwrite each other', () async {
      final storage = TestStorage.create();
      final service = CsvImportService(storage.open());

      await service.importCsvContent(
        'ID,Date,Category,Amount\n1,15-09-2026,Food,120\n',
        now: now,
      );
      await service.importCsvContent(
        'ID,Date,Category,Amount\n1,16-09-2026,Rent,900\n',
        now: now,
      );

      final titles = (await storage.transactionRows()).map((r) => r['title']);
      expect(titles, containsAll(['Food', 'Rent']));
    });

    test('an export imports back unchanged', () async {
      final source = TestStorage.create();
      final db = source.open();
      await db.saveTransactionMaps([
        {
          'id': 'e1',
          'title': '=SUM(A1)',
          'date': '01-09-2026',
          'amount': 12.5,
          'currency': 'INR',
          'is_income': 0,
          'bank_name': 'HDFC',
          'note': 'lunch, with friends',
          'timestamp': '26-09-01   12 : 00',
          'kind': 'expense',
        },
        {
          'id': 'a1',
          'title': 'Balance adjustment',
          'date': '02-09-2026',
          'amount': 30,
          'currency': 'INR',
          'is_income': 0,
          'bank_name': 'HDFC',
          'timestamp': '26-09-02   09 : 00',
          'kind': 'adjustment',
        },
      ]);
      final csv = CsvExportService.buildCsv(await db.getTransactionsMap());

      final target = TestStorage.create();
      final result =
          await CsvImportService(target.open()).importCsvContent(csv, now: now);

      expect(result.imported, 2);
      final rows = {
        for (final r in await target.transactionRows()) r['id']: r,
      };
      expect(rows['e1']!['title'], '=SUM(A1)');
      expect(rows['e1']!['note'], 'lunch, with friends');
      expect(rows['e1']!['amount'], 12.5);
      expect(rows['a1']!['kind'], 'adjustment');
      expect(rows['a1']!['amount'], 30);
      expect(rows['a1']!['is_income'], 0);
    });
  });
}
