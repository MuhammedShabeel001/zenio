import 'package:app/shared/utils/downloader/platform_helper.dart'
    if (dart.library.io) './other_downloader.dart'
    if (dart.library.js) './web_downloader.dart';

// ignore: one_member_abstracts
abstract class IPlatformDownloader {
  factory IPlatformDownloader() => getDownloader();
  Future<bool> downloadFile({
    required String url,
    required String filename,
    void Function(double)? onProgress,
    void Function(String)? onError,
  });
}
