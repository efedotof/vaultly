import 'dart:io';
import 'package:desktop_updater/updater_controller.dart';
import 'package:flutter/material.dart';
import 'update_service.dart';
import 'update_info.dart';

class DesktopUpdateService implements IUpdateService {
  final String appArchiveUrl;

  DesktopUpdateService({required this.appArchiveUrl});

  @override
  Future<UpdateInfo?> checkForUpdate() async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return null;
    }

    try {
      final controller = DesktopUpdaterController(
        appArchiveUrl: Uri.parse(appArchiveUrl),
      );

      try {
        await controller.checkVersion();
      } catch (e) {
        if (e.toString().contains('hashes.json') && controller.needUpdate) {
          debugPrint('Ignoring hashes.json error, update available');
        } else {
          rethrow;
        }
      }

      if (!controller.needUpdate) {
        return null;
      }

      return UpdateInfo(
        version: controller.appVersion ?? 'unknown',
        downloadUrl: appArchiveUrl,
        fileSize: 0,
      );
    } catch (e) {
      debugPrint('Desktop update check error: $e');
      return null;
    }
  }

  @override
  Future<bool> downloadAndInstall(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      debugPrint('downloadAndInstall: not desktop, skipping');
      return false;
    }

    try {
      debugPrint('Starting downloadAndInstall from: $downloadUrl');
      final controller = DesktopUpdaterController(
        appArchiveUrl: Uri.parse(downloadUrl),
      );

      debugPrint('Checking version before download...');
      await controller.checkVersion();

      if (!controller.needUpdate) {
        debugPrint('downloadAndInstall called but needUpdate is false');
        return false;
      }

      debugPrint('Starting downloadUpdate()...');
      await controller.downloadUpdate();

      debugPrint('Download complete, restarting app...');
      controller.restartApp();
      return true;
    } catch (e) {
      debugPrint('Desktop update installation failed: $e');
      return false;
    }
  }
}
