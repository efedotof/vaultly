import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:get/get.dart';
import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

enum AppOverlayStatus { none, checking, done, error, fileDecrypt, fileEnctypt}

class AppStatusOverlayController extends GetxController {
  final _config = Get.find<Config>();

  final state = AppOverlayStatus.none.obs;
  final hasInternet = true.obs;
  final isServerConnected = true.obs;

  final successBanner = false.obs;
  final successIcon = false.obs;
  final dismissed = false.obs;

  Timer? _timer;
  Timer? _successBannerTimer;
  Timer? _successIconTimer;
  Duration _currentInterval = _baseInterval;

  static const _baseInterval = Duration(seconds: 15);
  static const _maxInterval = Duration(minutes: 3);
  static const _requestTimeout = Duration(seconds: 5);
  static const _successFullDuration = Duration(milliseconds: 1200);
  static const _successIconDuration = Duration(milliseconds: 800);
  static const _tag = 'ConnectionCheckerController';
  static const _internetProbe = 'https://www.gstatic.com/generate_204';

  static final _random = Random();

  @override
  void onInit() {
    super.onInit();
    Logger.d(
      'Запуск проверки, база ${_baseInterval.inSeconds}s, макс ${_maxInterval.inSeconds}s',
      tag: _tag,
    );
    check();
  }

  @override
  void onClose() {
    Logger.d('Остановка проверки', tag: _tag);
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
    final sw = Stopwatch()..start();
    try {
      Logger.d('HEAD: $url', tag: _tag);
      final req = await client.headUrl(Uri.parse(url));
      final res = await req.close();
      await res.drain<void>();
      sw.stop();
      final ok = res.statusCode < 500;
      Logger.d(
        'Ответ $url: ${res.statusCode} (${sw.elapsedMilliseconds}ms) ok=$ok',
        tag: _tag,
      );
      return ok;
    } catch (e, s) {
      sw.stop();
      Logger.d(
        'Ошибка $url (${sw.elapsedMilliseconds}ms): ${e.runtimeType}: $e\n$s',
        tag: _tag,
      );
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
    } catch (e, s) {
      hasInternet.value = false;
      isServerConnected.value = false;
      state.value = AppOverlayStatus.error;
      Logger.d('Неожиданная ошибка: ${e.runtimeType}: $e\n$s', tag: _tag);
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
    final prev = _currentInterval;
    if (state.value == AppOverlayStatus.done) {
      _currentInterval = _baseInterval;
    } else {
      final next = _currentInterval * 2;
      _currentInterval = next > _maxInterval ? _maxInterval : next;
    }
    if (prev != _currentInterval) {
      Logger.d(
        'Интервал: ${prev.inSeconds}s → ${_currentInterval.inSeconds}s',
        tag: _tag,
      );
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    final jitterFactor = 0.85 + _random.nextDouble() * 0.30;
    final delayMs = (_currentInterval.inMilliseconds * jitterFactor).round();
    _timer = Timer(Duration(milliseconds: delayMs), check);
  }
}
