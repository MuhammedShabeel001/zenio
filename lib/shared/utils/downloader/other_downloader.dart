import 'dart:io';

import 'package:app/shared/utils/downloader/i_platform_downloader.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

IPlatformDownloader getDownloader() => OtherDownloader();

class OtherDownloader implements IPlatformDownloader {
  @override
  Future<bool> downloadFile({
    required String url,
    required String filename,
    void Function(double)? onProgress,
    void Function(String)? onError,
  }) async {
    try {
      // Request storage permission
      if (!await _checkPermission()) {
        if (onError != null) onError('Storage permission denied');
        return false;
      }

      // Get download directory
      final directory = await _getDownloadPath();
      if (directory == null) {
        if (onError != null) onError('Unable to access download directory');
        return false;
      }

      final filePath = '${directory.path}/$filename';

      // Download file using Dio
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      return true;
    } catch (e) {
      if (onError != null) onError(e.toString());
      return false;
    }
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        return result == PermissionStatus.granted;
      }
      return true;
    }
    return true; // iOS doesn't need runtime permission for downloads
  }

  Future<Directory?> _getDownloadPath() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    } else if (Platform.isWindows) {
      return getDownloadsDirectory();
    }
    return null;
  }
}
