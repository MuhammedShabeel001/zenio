import 'package:app/shared/utils/pdf/i_platform_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:printing/printing.dart';

IPdfPlatform getInstance() => PdfPlatformOther();

class PdfPlatformOther implements IPdfPlatform {
  @override
  Future<void> savePdf(Document pdf, {bool print = false}) async {
    // final output = await getDownloadsDirectory();
    // final file = File('${output!.path}/example.pdf');
    // await file.writeAsBytes(await pdf.save());
    if (print) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => pdf.save(),
      );
    }
  }
}
