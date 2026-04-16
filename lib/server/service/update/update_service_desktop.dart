import 'dart:io';
import 'package:desktop_updater/updater_controller.dart';
import 'package:vaulth_app/server/service/logger_service.dart';
import 'update_service.dart';
import 'update_info.dart';

class DesktopUpdateService implements IUpdateService {
  final String appArchiveUrl;
  final LoggerService _logger = LoggerService();

  DesktopUpdateService({required this.appArchiveUrl});

  @override
  Future<UpdateInfo?> checkForUpdate() async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      _logger.debug('DesktopUpdateService: not desktop, skipping');
      return null;
    }

    try {
      _logger.debug('Checking for desktop updates from: $appArchiveUrl');
      final controller = DesktopUpdaterController(
        appArchiveUrl: Uri.parse(appArchiveUrl),
      );
      await controller.checkVersion();

      if (!controller.needUpdate) {
        _logger.debug('No desktop update available');
        return null;
      }

      _logger.info('Update found: ${controller.appVersion}');
      return UpdateInfo(
        version: controller.appVersion ?? 'unknown',
        downloadUrl: appArchiveUrl,
        fileSize: 0,
      );
    } catch (e, stack) {
      _logger.error(
        'Error checking updates on desktop',
        error: e,
        stackTrace: stack,
      );
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
      if (!controller.needUpdate) return false;

      await controller.downloadUpdate();
      controller.restartApp();
      return true;
    } catch (e) {
      _logger.error('Desktop update installation failed', error: e);
      return false;
    }
  }
}
