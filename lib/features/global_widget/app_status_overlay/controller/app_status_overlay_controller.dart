import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/exception/new_version_exception.dart';
import 'package:vaulth_app/server/exception/no_update_required_exception.dart';
import 'package:vaulth_app/server/exception/update_check_failed_exception.dart';
import 'package:vaulth_app/server/service/updater/updater.dart';

enum AppOverlayStatus {
  none,
  checking,
  done,
  error,
  fileDecrypt,
  fileEncrypt,
  updateAvailable,
  downloadingUpdate,
  noUpdate,
  failedUpdate,
  webVersion,
}

class AppStatusOverlayController extends GetxController {
  final _config = Get.find<Config>();

  final state = AppOverlayStatus.none.obs;
  final hasInternet = true.obs;
  final isServerConnected = true.obs;

  final successBanner = false.obs;
  final successIcon = false.obs;
  final dismissed = false.obs;

  final downloadProgress = 0.0.obs;
  final downloadedBytes = 0.obs;
  final totalBytes = 0.obs;

  Timer? _timer;
  Timer? _successBannerTimer;
  Timer? _successIconTimer;
  Duration _currentInterval = _baseInterval;

  static const _baseInterval = Duration(seconds: 15);
  static const _maxInterval = Duration(minutes: 3);
  static const _requestTimeout = Duration(seconds: 5);
  static const _successFullDuration = Duration(milliseconds: 1200);
  static const _successIconDuration = Duration(milliseconds: 800);
  static const _internetProbe = 'https://www.gstatic.com/generate_204';

  static final _random = Random();

  @override
  void onInit() {
    super.onInit();
    check();
    checkUpgrade();
  }

  @override
  void onClose() {
    _timer?.cancel();
    _successBannerTimer?.cancel();
    _successIconTimer?.cancel();
    super.onClose();
  }

  void dismiss() => dismissed.value = true;

  void dismissSuccess() {
    _successBannerTimer?.cancel();
    _successIconTimer?.cancel();
    successBanner.value = false;
    successIcon.value = false;
  }

  Future<bool> _ping(String url) async {
    final client = HttpClient();
    client.connectionTimeout = _requestTimeout;
    try {
      final req = await client.headUrl(Uri.parse(url));
      final res = await req.close();
      await res.drain<void>();
      return res.statusCode < 500;
    } catch (e) {
      return false;
    } finally {
      client.close();
    }
  }

  Future<void> check() async {
    if (state.value == AppOverlayStatus.checking) return;
    _timer?.cancel();
    state.value = AppOverlayStatus.checking;

    final wasConnected = hasInternet.value && isServerConnected.value;

    try {
      final internet = await _ping(_internetProbe);
      hasInternet.value = internet;

      if (!internet) {
        isServerConnected.value = false;
        state.value = AppOverlayStatus.error;
      } else {
        final healthUrl = '${_config.baseUrl}${_config.authPath}/health';
        final server = await _ping(healthUrl);
        isServerConnected.value = server;
        state.value = server ? AppOverlayStatus.done : AppOverlayStatus.error;
      }
    } catch (e) {
      hasInternet.value = false;
      isServerConnected.value = false;
      state.value = AppOverlayStatus.error;
    } finally {
      final nowConnected = hasInternet.value && isServerConnected.value;

      if (wasConnected != nowConnected) {
        dismissed.value = false;
      }

      if (!nowConnected) {
        _successBannerTimer?.cancel();
        _successIconTimer?.cancel();
        successBanner.value = false;
        successIcon.value = false;
      } else if (!wasConnected) {
        _showSuccessSequence();
      }

      _applyBackoff();
      _scheduleNext();
    }
  }

  void _showSuccessSequence() {
    _successBannerTimer?.cancel();
    _successIconTimer?.cancel();

    successBanner.value = true;
    successIcon.value = false;

    _successBannerTimer = Timer(_successFullDuration, () {
      successBanner.value = false;
      successIcon.value = true;
    });

    _successIconTimer = Timer(
      _successFullDuration + _successIconDuration,
      () => successIcon.value = false,
    );
  }

  void _applyBackoff() {
    if (state.value == AppOverlayStatus.done) {
      _currentInterval = _baseInterval;
    } else {
      final next = _currentInterval * 2;
      _currentInterval = next > _maxInterval ? _maxInterval : next;
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    final jitterFactor = 0.85 + _random.nextDouble() * 0.30;
    final delayMs = (_currentInterval.inMilliseconds * jitterFactor).round();
    _timer = Timer(Duration(milliseconds: delayMs), check);
  }

  Future<void> checkUpgrade() async {
    if (kIsWeb) {
      state.value = AppOverlayStatus.webVersion;
      return;
    }

    try {
      final updater = Get.find<UpdaterUnplatform>();
      await updater.checkNewVersion();
    } on UpdateCheckFailedException catch (_) {
      state.value = AppOverlayStatus.failedUpdate;
    } on NewVersionException catch (_) {
      state.value = AppOverlayStatus.updateAvailable;
      dismissed.value = false;
    } on NoUpdateRequiredException catch (_) {
      state.value = AppOverlayStatus.noUpdate;
      dismissed.value = false;
    } catch (e) {
      state.value = AppOverlayStatus.failedUpdate;
    }
  }

  Future<void> startUpdate() async {
    if (kIsWeb) return;

    state.value = AppOverlayStatus.downloadingUpdate;
    downloadProgress.value = 0.0;
    downloadedBytes.value = 0;
    totalBytes.value = 0;
    dismissed.value = false;

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
      state.value = AppOverlayStatus.failedUpdate;
    } catch (e) {
      state.value = AppOverlayStatus.failedUpdate;
    }
  }
}
