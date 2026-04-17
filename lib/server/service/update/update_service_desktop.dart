import 'dart:io';
import 'package:desktop_updater/updater_controller.dart';
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

      await controller.checkVersion();

      if (!controller.needUpdate) {
        return null;
      }

      return UpdateInfo(
        version: controller.appVersion ?? 'unknown',
        downloadUrl: appArchiveUrl,
        fileSize: 0,
      );
    } catch (e) {
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
      final controller = DesktopUpdaterController(
        appArchiveUrl: Uri.parse(downloadUrl),
      );

      await controller.checkVersion();

      if (!controller.needUpdate) {
        return false;
      }

      await controller.downloadUpdate();
      controller.restartApp();
      return true;
    } catch (e) {
      return false;
    }
  }
}
