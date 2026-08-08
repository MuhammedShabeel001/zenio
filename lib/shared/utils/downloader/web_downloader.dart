// ignore: avoid_web_libraries_in_flutter
// import 'dart:html' as html;

import 'package:app/shared/utils/downloader/i_platform_downloader.dart';

IPlatformDownloader getDownloader() => WebDownloader();

class WebDownloader implements IPlatformDownloader {
  @override
  Future<bool> downloadFile({
    required String url,
    required String filename,
    void Function(double)? onProgress,
    void Function(String)? onError,
  }) async {
    try {
      // Create anchor element
      // final anchor = html.AnchorElement(href: url)
      //   ..target = '_blank'
      //   ..download = filename;

      // // Trigger download by simulating click
      // html.document.body?.append(anchor);
      // anchor
      //   ..click()
      //   ..remove();
      // Since web downloads are handled by the browser,
      // we can't track progress but can simulate completion
      if (onProgress != null) {
        onProgress(1);
      }
      return true;
    } catch (e) {
      if (onError != null) onError(e.toString());
      return false;
    }
  }
}
