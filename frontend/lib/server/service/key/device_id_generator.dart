import 'dart:convert';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:vaulth_app/server/service/system/logger_service.dart';

class DeviceIdGenerator {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final LoggerService _logger = LoggerService();

  Future<String> generateDeviceId() async {
    try {
      if (kIsWeb) {
        return await _generateWebId();
      }
      if (Platform.isAndroid) {
        return await _generateAndroidId();
      } else if (Platform.isIOS) {
        return await _generateIosId();
      } else if (Platform.isWindows) {
        return await _generateWindowsId();
      } else if (Platform.isMacOS) {
        return await _generateMacOsId();
      } else if (Platform.isLinux) {
        return await _generateLinuxId();
      } else {
        return await _generateWebId();
      }
    } catch (e, stack) {
      _logger.error('DeviceIdGenerator error', error: e, stackTrace: stack);
      return _fallbackRandomId();
    }
  }

  Future<String> _generateAndroidId() async {
    final info = await _deviceInfo.androidInfo;
    final components = [
      info.id,
      info.board,
      info.bootloader,
      info.brand,
      info.device,
      info.display,
      info.fingerprint,
      info.hardware,
      info.manufacturer,
      info.model,
      info.product,
      info.tags,
      info.type,
    ];
    return _hashComponents(components);
  }

  Future<String> _generateIosId() async {
    final info = await _deviceInfo.iosInfo;
    final components = [
      info.identifierForVendor,
      info.name,
      info.model,
      info.systemName,
      info.systemVersion,
      info.localizedModel,
      info.utsname.machine,
    ];
    return _hashComponents(components);
  }

  Future<String> _generateWindowsId() async {
    final info = await _deviceInfo.windowsInfo;
    final components = [
      info.deviceId,
      info.computerName,
      info.productId,
      info.numberOfCores,
      info.majorVersion,
      info.minorVersion,
      info.buildNumber,
      info.productName,
    ];
    return _hashComponents(components);
  }

  Future<String> _generateMacOsId() async {
    final info = await _deviceInfo.macOsInfo;
    final components = [
      info.systemGUID,
      info.computerName,
      info.model,
      info.modelName,
      info.kernelVersion,
      info.osRelease,
      info.arch,
    ];
    return _hashComponents(components);
  }

  Future<String> _generateLinuxId() async {
    final info = await _deviceInfo.linuxInfo;
    final components = [
      info.machineId,
      info.id,
      info.name,
      info.version,
      info.prettyName,
      info.versionId,
    ];
    return _hashComponents(components);
  }

  Future<String> _generateWebId() async {
    final info = await _deviceInfo.webBrowserInfo;
    final components = [
      info.userAgent,
      info.platform,
      info.language,
      info.hardwareConcurrency,
      info.maxTouchPoints,
    ];
    return _hashComponents(components);
  }

  String _hashComponents(List<Object?> components) {
    final combined = components.where((c) => c != null).join('|');
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _fallbackRandomId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final id = base64Url.encode(bytes);
    _logger.warning('Using fallback random device ID: $id');
    return id;
  }
}
