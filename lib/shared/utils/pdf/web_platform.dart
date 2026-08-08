import 'package:app/shared/utils/pdf/i_platform_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:printing/printing.dart';

IPdfPlatform getInstance() => PdfPlatformWeb();

class PdfPlatformWeb implements IPdfPlatform {
  @override
  Future<void> savePdf(Document pdf, {bool print = false}) async {
    final savedFile = await pdf.save();
    // final fileInts = List<int>.from(savedFile);
    // html.AnchorElement(
    //   href:
    //       'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(fileInts)}',
    // )
    //   ..setAttribute(
    //     'download',
    //     '${DateTime.now().millisecondsSinceEpoch}.pdf',
    //   )
    //   ..click();
    if (print) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => savedFile,
      );
    }
  }
}
