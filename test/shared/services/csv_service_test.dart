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

    test('writes dates older versions stored in the importable format', () {
      final csv = CsvExportService.buildCsv([
        {
          'id': '1',
          'title': 'Food',
          'date': 'Thursday, September 17, 2026',
          'amount': 10,
          'currency': 'INR',
          'is_income': 0,
          'bank_name': 'HDFC',
        },
      ]);

      expect(csv, contains('\n17-09-2026,Expense,Food,10,'));
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

    test('reads the long dates older versions stored', () async {
      final storage = TestStorage.create();
      final service = CsvImportService(storage.open());

      final result = await service.importCsvContent(
        'Date,Type,Category,Amount,Wallet\n'
        '"Thursday, September 17, 2026",Expense,Food,10,HDFC\n'
        '"September 18, 2026",Expense,Taxi,20,HDFC\n',
        now: now,
      );

      expect(result.imported, 2);
      final dates = (await storage.transactionRows()).map((r) => r['date']);
      expect(dates, containsAll(['17-09-2026', '18-09-2026']));
    });

    test('reads amounts written with a currency and skips unclear ones',
        () async {
      final storage = TestStorage.create();
      final service = CsvImportService(storage.open());

      final result = await service.importCsvContent(
        'Date,Type,Category,Amount,Wallet\n'
        '15-09-2026,Expense,Rupees dot,Rs. 500,HDFC\n'
        '15-09-2026,Expense,Rupees no space,"Rs.1,00,000",HDFC\n'
        '15-09-2026,Expense,Symbol,"₹ 1,234.50",HDFC\n'
        '15-09-2026,Adjustment,Down,-₹ 20,HDFC\n'
        '15-09-2026,Expense,Decimal comma,"1.234,50",HDFC\n'
        '15-09-2026,Expense,Short group,"12,5",HDFC\n'
        '15-09-2026,Expense,Leading dot,.5,HDFC\n',
        now: now,
      );

      expect(result.imported, 4);
      expect(result.skipped, 3);
      final rows = {
        for (final r in await storage.transactionRows()) r['title']: r,
      };
      expect(rows['Rupees dot']!['amount'], 500);
      expect(rows['Rupees no space']!['amount'], 100000);
      expect(rows['Symbol']!['amount'], 1234.5);
      expect(rows['Down']!['amount'], 20);
      expect(rows['Down']!['is_income'], 0);
    });

    test('rows without a wallet get a named wallet even with no default',
        () async {
      final storage = TestStorage.create();
      final service = CsvImportService(storage.open());

      // The default wallet setting is empty until a wallet exists.
      await service.importCsvContent(
        'Date,Category,Amount\n15-09-2026,Food,120\n',
        defaultWallet: '',
        now: now,
      );

      final row = (await storage.transactionRows()).single;
      expect(row['bank_name'], 'Default Wallet');
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
