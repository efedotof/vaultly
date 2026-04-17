import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:velopack_flutter/velopack_flutter.dart';
import 'update_service.dart';
import 'update_info.dart';

class VelopackUpdateService implements IUpdateService {
  final String updateUrl;

  VelopackUpdateService({required this.updateUrl});

  @override
  Future<UpdateInfo?> checkForUpdate() async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return null;
    }
    try {
      final available = await isUpdateAvailable(url: updateUrl);
      if (!available) return null;

      return UpdateInfo(
        version: 'unknown',
        downloadUrl: updateUrl,
        fileSize: 0,
      );
    } catch (e) {
      debugPrint('Velopack checkForUpdates error: $e');
      return null;
    }
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
      await updateAndRestart(url: updateUrl);
      return true;
    } catch (e) {
      debugPrint('Velopack updateAndRestart error: $e');
      return false;
    }
  }
}
