import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:vaulth_app/server/service/logger_service.dart';
import 'update_info.dart';
import 'update_service_android.dart';
import 'update_service_velopack.dart';

abstract class IUpdateService {
  Future<UpdateInfo?> checkForUpdate();
  Future<bool> downloadAndInstall(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  });
}

class UpdateService implements IUpdateService {
  final IUpdateService _platformService;
  final LoggerService _logger = LoggerService();

  UpdateService({required String githubRepoUrl, required String appArchiveUrl})
    : _platformService = _createPlatformService(
        githubRepoUrl: githubRepoUrl,
        appArchiveUrl: appArchiveUrl,
      );

  static IUpdateService _createPlatformService({
    required String githubRepoUrl,
    required String appArchiveUrl,
  }) {
    if (kIsWeb) return _NoOpUpdateService();
    if (Platform.isAndroid) {
      return AndroidUpdateService(githubRepoUrl: githubRepoUrl);
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Используем Velopack
      const velopackUpdateUrl =
          'https://github.com/efedotof/vaultly/releases/latest/download/releases.json';
      return VelopackUpdateService(updateUrl: velopackUpdateUrl);
    } else {
      return _NoOpUpdateService();
    }
  }

  @override
  Future<UpdateInfo?> checkForUpdate() async {
    _logger.debug('UpdateService: checking for updates');
    return _platformService.checkForUpdate();
  }

  @override
  Future<bool> downloadAndInstall(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    _logger.debug('UpdateService: starting download and install');
    return _platformService.downloadAndInstall(
      downloadUrl,
      onProgress: onProgress,
    );
  }
}

class _NoOpUpdateService implements IUpdateService {
  @override
  Future<UpdateInfo?> checkForUpdate() async => null;

  @override
  Future<bool> downloadAndInstall(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async => false;
}
