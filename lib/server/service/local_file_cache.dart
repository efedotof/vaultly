import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:vaulth_app/server/service/logger_service.dart';

class LocalFileCache {
  final LoggerService _logger = LoggerService();

  bool get _isSupported => !kIsWeb;

  Future<Directory> _getCacheDirectory() async {
    if (!_isSupported) {
      throw UnsupportedError(
        'Кэширование файлов не поддерживается на веб-платформе',
      );
    }
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/file_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  Future<void> saveFile(
    String fileId,
    Uint8List data, {
    String? originalName,
  }) async {
    if (!_isSupported) {
      _logger.debug('[LocalFileCache] Кэширование отключено на веб-платформе');
      return;
    }
    try {
      final cacheDir = await _getCacheDirectory();
      final file = File('${cacheDir.path}/$fileId');
      await file.writeAsBytes(data);

      if (originalName != null && originalName.isNotEmpty) {
        final nameFile = File('${cacheDir.path}/$fileId.name');
        await nameFile.writeAsString(originalName);
      }

      _logger.debug('[LocalFileCache] Файл $fileId сохранён в кэш');
    } catch (e) {
      _logger.error(
        '[LocalFileCache] Ошибка сохранения файла $fileId',
        error: e,
      );
    }
  }

  Future<bool> hasFile(String fileId) async {
    if (!_isSupported) return false;
    try {
      final cacheDir = await _getCacheDirectory();
      final file = File('${cacheDir.path}/$fileId');
      return await file.exists();
    } catch (e) {
      _logger.error(
        '[LocalFileCache] Ошибка проверки наличия файла $fileId',
        error: e,
      );
      return false;
    }
  }

  Future<Uint8List?> getFile(String fileId) async {
    if (!_isSupported) return null;
    try {
      final cacheDir = await _getCacheDirectory();
      final file = File('${cacheDir.path}/$fileId');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        _logger.debug('[LocalFileCache] Файл $fileId загружен из кэша');
        return Uint8List.fromList(bytes);
      }
      return null;
    } catch (e) {
      _logger.error(
        '[LocalFileCache] Ошибка загрузки файла $fileId из кэша',
        error: e,
      );
      return null;
    }
  }

  Future<String?> getOriginalName(String fileId) async {
    if (!_isSupported) return null;
    try {
      final cacheDir = await _getCacheDirectory();
      final nameFile = File('${cacheDir.path}/$fileId.name');
      if (await nameFile.exists()) {
        return await nameFile.readAsString();
      }
      return null;
    } catch (e) {
      _logger.error(
        '[LocalFileCache] Ошибка загрузки оригинального имени $fileId',
        error: e,
      );
      return null;
    }
  }

  Future<void> deleteFile(String fileId) async {
    if (!_isSupported) return;
    try {
      final cacheDir = await _getCacheDirectory();
      final file = File('${cacheDir.path}/$fileId');
      if (await file.exists()) {
        await file.delete();
      }
      final nameFile = File('${cacheDir.path}/$fileId.name');
      if (await nameFile.exists()) {
        await nameFile.delete();
      }
      _logger.debug('[LocalFileCache] Файл $fileId удалён из кэша');
    } catch (e) {
      _logger.error('[LocalFileCache] Ошибка удаления файла $fileId', error: e);
    }
  }

  Future<void> clearCache() async {
    if (!_isSupported) return;
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      _logger.debug('[LocalFileCache] Кэш полностью очищен');
    } catch (e) {
      _logger.error('[LocalFileCache] Ошибка очистки кэша', error: e);
    }
  }

  Future<int> getCacheSize() async {
    if (!_isSupported) return 0;
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) return 0;
      return await _calculateDirSize(cacheDir);
    } catch (e) {
      _logger.error('[LocalFileCache] Ошибка получения размера кэша', error: e);
      return 0;
    }
  }

  Future<int> _calculateDirSize(Directory dir) async {
    int total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
