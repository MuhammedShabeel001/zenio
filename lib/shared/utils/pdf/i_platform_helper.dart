import 'package:pdf/widgets.dart';
import 'package:zenio/shared/utils/pdf/platform_helper.dart'
    if (dart.library.html) './web_platform.dart'
    if (dart.library.io) './other_platform.dart';

// ignore: one_member_abstracts
abstract class IPdfPlatform {
  factory IPdfPlatform() => getInstance();
  Future<void> savePdf(Document pdf, {bool print = false});
}
