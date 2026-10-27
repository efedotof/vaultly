import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qnd_updater/qnd_updater.dart';
import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/exception/new_version_exception.dart';
import 'package:vaulth_app/server/exception/no_update_required_exception.dart';
import 'package:vaulth_app/server/exception/update_check_failed_exception.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

class UpdaterUnplatform extends GetxService {
  bool _isInit = false;
  final Config _config;
  final updater = QndUpdater();

  UpdaterUnplatform({required Config config}) : _config = config;

  Future<UpdaterUnplatform> init() async {
    _isInit = true;
    return this;
  }

  bool get isInitial => _isInit;

  Future<void> checkNewVersion() async {
    final status = await updater.checkForUpdate(
      githubToken: _config.githubToken,
      owner: _config.githubOwner,
      repo: _config.githubRepo,
    );

    switch (status) {
      case UpdateStatus.updateAvailable:
        throw NewVersionException();
      case UpdateStatus.upToDate:
        throw NoUpdateRequiredException();
      case UpdateStatus.error:
        throw UpdateCheckFailedException();
    }
  }

  Future<void> downloadAndApply({
    required void Function(int done, int total) onProgress,
  }) async {
    final service = UpdaterService(
      owner: _config.githubOwner,
      repo: _config.githubRepo,
    );

    final platformKey = Platform.isWindows
        ? 'windows'
        : Platform.isMacOS
        ? 'macos'
        : Platform.isLinux
        ? 'linux'
        : 'android';

    final tmp = await getTemporaryDirectory();
    final staging = Directory('${tmp.path}/qnd_staging');

    final result = await service.downloadUpdate(
      platformKey: platformKey,
      stagingDir: staging,
      onProgress: onProgress,
    );

    if (result == null) {
      Logger.d(
        'Ассет для платформы $platformKey не найден',
        tag: "UpdaterUnplatform",
      );
      throw UpdateCheckFailedException();
    }

    await updater.applyUpdate(result.stagingDir.path);

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await Future.delayed(const Duration(milliseconds: 500));
      exit(0);
    }
  }
}
