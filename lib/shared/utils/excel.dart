import 'dart:io';
import 'package:app/shared/shared.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<void> exportToExcel(
  List<Map<String, dynamic>> data,
  String title,
) async {
  final excel = Excel.createExcel();
  excel
    ..rename(excel.sheets.keys.first, title)
    ..appendRow(
      title,
      data.first.keys.map((e) => TextCellValue(e.displayCase)).toList(),
    );
  for (final cust in data) {
    excel.appendRow(
      title,
      cust.entries
          .map((e) => TextCellValue(e.value?.toString() ?? ''))
          .toList(),
    );
  }

  if (kIsWeb) {
    excel.save(fileName: '$title.xlsx');
  } else {
    final bytes = excel.save();

    final directory = await getApplicationDocumentsDirectory();
    File(join(directory.path, '$title.xlsx'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
  }
}
