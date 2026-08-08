import 'package:app/shared/shared.dart';
import 'package:hancod_theme/hancod_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' hide Table;

enum PrintFormats {
  a4,
  roll80,
  roll57,
}

class PdfService {
  static const double inch = PdfPageFormat.inch;
  static const double mm = PdfPageFormat.mm;

  static Future<void> _downloadPdf(Document pdf, {bool print = false}) async {
    try {
      await IPdfPlatform().savePdf(pdf, print: print);
    } catch (e) {
      Alert.showSnackBar(e.toString(), type: SnackBarType.error);
    }
  }

  static Future<void> printQR(String qr) async {
    final pdf = Document()
      ..addPage(
        Page(
          build: (context) {
            return BarcodeWidget(
              color: PdfColor.fromHex('#000000'),
              barcode: Barcode.qrCode(),
              //https://dinenorder-customer-dev.web.app/home/restaurant/ff0b8f8e-4ab3-407a-83a4-87897f8a2a2d?tableId=1402e1d4-5652-4360-b3fd-58e6b0339284
              data: qr,
            );
          },
        ),
      ); // Page
    await _downloadPdf(pdf, print: true);
  }
}
