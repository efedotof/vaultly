import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:qnd_updater/qnd_updater.dart';
import 'package:vaulth_app/server/exception/new_version_exception.dart';
import 'package:vaulth_app/server/exception/no_update_required_exception.dart';
import 'package:vaulth_app/server/exception/update_check_failed_exception.dart';
import 'package:vaulth_app/server/service/updater/updater.dart';

enum SettingsState {
  idle,
  checking,
  updateAvailable,
  downloadingUpdate,
  noUpdate,
  failedUpdate,
  webVersion,
}

class SettingsController extends GetxController {
  final state = SettingsState.idle.obs;

  final downloadProgress = 0.0.obs;
  final downloadedBytes = 0.obs;
  final totalBytes = 0.obs;

  final appVersion = "".obs;

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
    checkUpgrade();
  }

  Future<void> _loadAppVersion() async {
    if (kIsWeb) {
      appVersion.value = "web";
      return;
    }
    final version = await QndUpdater().getAppVersion();
    appVersion.value = version ?? "";
  }

  Future<void> checkUpgrade() async {
    if (kIsWeb) {
      state.value = SettingsState.webVersion;
      return;
    }

    if (state.value == SettingsState.checking || state.value == SettingsState.downloadingUpdate) {
      return;
    }

    state.value = SettingsState.checking;

    try {
      final updater = Get.find<UpdaterUnplatform>();
      await updater.checkNewVersion();
    } on UpdateCheckFailedException catch (_) {
      state.value = SettingsState.failedUpdate;
    } on NewVersionException catch (_) {
      state.value = SettingsState.updateAvailable;
    } on NoUpdateRequiredException catch (_) {
      state.value = SettingsState.noUpdate;
    } catch (e) {
      state.value = SettingsState.failedUpdate;
    }
  }

  Future<void> startUpdate() async {
    if (kIsWeb) return;

    state.value = SettingsState.downloadingUpdate;
    downloadProgress.value = 0.0;
    downloadedBytes.value = 0;
    totalBytes.value = 0;

    try {
      final updater = Get.find<UpdaterUnplatform>();
      await updater.downloadAndApply(
        onProgress: (done, total) {
          downloadedBytes.value = done;
          totalBytes.value = total;
          if (total > 0) {
            downloadProgress.value = done / total;
          }
        },
      );
    } on UpdateCheckFailedException catch (_) {
      state.value = SettingsState.failedUpdate;
    } catch (e) {
      state.value = SettingsState.failedUpdate;
    }
  }
}