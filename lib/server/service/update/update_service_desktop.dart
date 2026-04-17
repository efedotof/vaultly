import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'update_service.dart';
import 'update_info.dart';

class DesktopUpdateService implements IUpdateService {
  final String appArchiveUrl;

  DesktopUpdateService({required this.appArchiveUrl});

  String get _platform {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  Future<UpdateInfo?> _fetchUpdateInfo() async {
    try {
      final dio = Dio();
      final response = await dio.get(appArchiveUrl);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.data as String);
      final items = data['items'] as List?;
      if (items == null) return null;

      Map<String, dynamic>? platformItem;
      for (final item in items) {
        if (item['platform'] == _platform) {
          platformItem = item as Map<String, dynamic>;
          break;
        }
      }
      if (platformItem == null) return null;

      final version = platformItem['version'] as String? ?? 'unknown';
      final downloadUrl = platformItem['url'] as String?;
      if (downloadUrl == null) return null;

      return UpdateInfo(
        version: version,
        downloadUrl: downloadUrl,
        fileSize: 0,
      );
    } catch (e) {
      debugPrint('Error fetching update info: $e');
      return null;
    }
  }

  @override
  Future<UpdateInfo?> checkForUpdate() async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return null;
    }

    try {
      final updateInfo = await _fetchUpdateInfo();
      if (updateInfo == null) return null;

      final currentVersion = await _getCurrentVersion();
      if (currentVersion == updateInfo.version) {
        return null;
      }
      return updateInfo;
    } catch (e) {
      debugPrint('Desktop update check error: $e');
      return null;
    }
  }

  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  Future<bool> downloadAndInstall(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return false;
    }

    try {
      final dir =
          await getDownloadsDirectory() ?? await getTemporaryDirectory();
      final fileName = downloadUrl.split('/').last;
      final filePath = '${dir.path}/$fileName';

      final dio = Dio();
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Desktop update installation failed: $e');
      return false;
    }
  }
}
