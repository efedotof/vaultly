import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:vaulth_app/server/service/logger_service.dart';
import 'package:vaulth_app/storage/secure_storage_adapter.dart';
import 'package:webcrypto/webcrypto.dart' as web;
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/api.dart' show AEADParameters, KeyParameter;

class LocalFileCache {
  final LoggerService _logger = LoggerService();
  late final Database _db;
  late final StoreRef<String, Map<String, dynamic>> _store;
  bool _initialized = false;

  static const String _keyPrefix = 'cache_key_';

  Future<void> _init() async {
    if (_initialized) {
      _logger.debug('[LocalFileCache] Already initialized');
      return;
    }
    try {
      final factory = kIsWeb ? databaseFactoryWeb : databaseFactoryIo;
      String dbPath;
      if (kIsWeb) {
        dbPath = 'file_cache.db';
        _logger.debug('[LocalFileCache] Web mode, using database: $dbPath');
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        dbPath = '${appDir.path}/file_cache.db';
        _logger.debug('[LocalFileCache] Native mode, database path: $dbPath');
      }
      _db = await factory.openDatabase(dbPath);
      _store = StoreRef.main();
      _initialized = true;
      _logger.debug('[LocalFileCache] Database initialized successfully');
    } catch (e, stack) {
      _logger.error('[LocalFileCache] INIT ERROR', error: e, stackTrace: stack);
      rethrow;
    }
  }

  (Uint8List key, Uint8List nonce) _generateKeyAndNonce() {
    final random = Random.secure();
    final key = Uint8List(32);
    final nonce = Uint8List(12);
    for (int i = 0; i < 32; i++) {
      key[i] = random.nextInt(256);
    }
    for (int i = 0; i < 12; i++) {
      nonce[i] = random.nextInt(256);
    }
    return (key, nonce);
  }

  Future<void> _saveFileKey(String fileId, Uint8List key) async {
    try {
      await SecureStorageAdapter.write(
        key: '$_keyPrefix$fileId',
        value: base64Encode(key),
      );
      _logger.debug('[LocalFileCache] Key saved for $fileId');
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] Failed to save key for $fileId',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<Uint8List?> _getFileKey(String fileId) async {
    try {
      final b64 = await SecureStorageAdapter.read(key: '$_keyPrefix$fileId');
      if (b64 == null) {
        _logger.warning('[LocalFileCache] No key found for $fileId');
        return null;
      }
      return base64Decode(b64);
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] Failed to read key for $fileId',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  Future<void> _deleteFileKey(String fileId) async {
    try {
      await SecureStorageAdapter.delete(key: '$_keyPrefix$fileId');
      _logger.debug('[LocalFileCache] Key deleted for $fileId');
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] Failed to delete key for $fileId',
        error: e,
        stackTrace: stack,
      );
      // Не пробрасываем исключение, чтобы не ломать удаление записи из БД
    }
  }

  Future<Uint8List> _aesGcmEncrypt(
    Uint8List plaintext,
    Uint8List key,
    Uint8List nonce,
  ) async {
    try {
      if (kIsWeb) {
        final secretKey = await web.AesGcmSecretKey.importRawKey(key);
        return await secretKey.encryptBytes(plaintext, nonce);
      } else {
        final keyParam = KeyParameter(key);
        final gcm = GCMBlockCipher(AESEngine())
          ..init(true, AEADParameters(keyParam, 128, nonce, Uint8List(0)));
        final ciphertext = Uint8List(gcm.getOutputSize(plaintext.length));
        final processed = gcm.processBytes(
          plaintext,
          0,
          plaintext.length,
          ciphertext,
          0,
        );
        final finalised = gcm.doFinal(ciphertext, processed);
        final total = processed + finalised;
        return Uint8List.sublistView(ciphertext, 0, total);
      }
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] AES-GCM encryption failed',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<Uint8List> _aesGcmDecrypt(
    Uint8List ciphertext,
    Uint8List key,
    Uint8List nonce,
  ) async {
    try {
      if (kIsWeb) {
        final secretKey = await web.AesGcmSecretKey.importRawKey(key);
        return await secretKey.decryptBytes(ciphertext, nonce);
      } else {
        final keyParam = KeyParameter(key);
        final gcm = GCMBlockCipher(AESEngine())
          ..init(false, AEADParameters(keyParam, 128, nonce, Uint8List(0)));
        final plaintext = Uint8List(gcm.getOutputSize(ciphertext.length));
        final processed = gcm.processBytes(
          ciphertext,
          0,
          ciphertext.length,
          plaintext,
          0,
        );
        final finalised = gcm.doFinal(plaintext, processed);
        final total = processed + finalised;
        return Uint8List.sublistView(plaintext, 0, total);
      }
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] AES-GCM decryption failed',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> saveFile(
    String fileId,
    Uint8List data, {
    String? originalName,
  }) async {
    _logger.debug(
      '[LocalFileCache] saveFile called for $fileId, size: ${data.length} bytes',
    );
    await _init();
    try {
      final (key, nonce) = _generateKeyAndNonce();
      _logger.debug('[LocalFileCache] Generated key and nonce for $fileId');

      final encryptedData = await _aesGcmEncrypt(data, key, nonce);
      _logger.debug(
        '[LocalFileCache] Data encrypted for $fileId, encrypted size: ${encryptedData.length} bytes',
      );

      await _saveFileKey(fileId, key);

      final record = {
        'id': fileId,
        'encryptedData': encryptedData,
        'nonce': nonce,
        'originalName': originalName ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _store.record(fileId).put(_db, record);
      _logger.debug(
        '[LocalFileCache] File $fileId saved to cache successfully',
      );
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] Error saving file $fileId',
        error: e,
        stackTrace: stack,
      );
      // Не пробрасываем исключение, чтобы не ломать вызывающий код
    }
  }

  Future<bool> hasFile(String fileId) async {
    _logger.debug('[LocalFileCache] hasFile called for $fileId');
    await _init();
    try {
      final snapshot = await _store.record(fileId).getSnapshot(_db);
      final exists = snapshot != null;
      _logger.debug('[LocalFileCache] File $fileId exists in cache: $exists');
      return exists;
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] Error checking file existence $fileId',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  Future<Uint8List?> getFile(String fileId) async {
    _logger.debug('[LocalFileCache] getFile called for $fileId');
    await _init();
    try {
      final record = await _store.record(fileId).get(_db);
      if (record == null) {
        _logger.debug('[LocalFileCache] No record found for $fileId');
        return null;
      }

      final encryptedData = record['encryptedData'] as Uint8List?;
      final nonce = record['nonce'] as Uint8List?;
      if (encryptedData == null || nonce == null) {
        _logger.error('[LocalFileCache] Invalid record data for $fileId');
        return null;
      }

      final key = await _getFileKey(fileId);
      if (key == null) {
        _logger.warning('[LocalFileCache] Key not found for $fileId');
        return null;
      }

      final plaintext = await _aesGcmDecrypt(encryptedData, key, nonce);
      _logger.debug(
        '[LocalFileCache] File $fileId decrypted successfully, size: ${plaintext.length} bytes',
      );
      return plaintext;
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] Error retrieving/decrypting file $fileId',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  Future<String?> getOriginalName(String fileId) async {
    _logger.debug('[LocalFileCache] getOriginalName called for $fileId');
    await _init();
    try {
      final record = await _store.record(fileId).get(_db);
      return record?['originalName'] as String?;
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] Error getting original name for $fileId',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  Future<void> deleteFile(String fileId) async {
    _logger.debug('[LocalFileCache] deleteFile called for $fileId');
    await _init();
    try {
      await _store.record(fileId).delete(_db);
      await _deleteFileKey(fileId);
      _logger.debug('[LocalFileCache] File $fileId and its key deleted');
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] Error deleting file $fileId',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> clearCache() async {
    _logger.debug('[LocalFileCache] clearCache called');
    await _init();
    try {
      final keys = await _store.findKeys(_db);
      for (final key in keys) {
        await _deleteFileKey(key.toString());
      }
      await _store.drop(_db);
      _logger.debug('[LocalFileCache] Cache cleared completely');
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] Error clearing cache',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<int> getCacheSize() async {
    _logger.debug('[LocalFileCache] getCacheSize called');
    await _init();
    try {
      final finder = Finder();
      final records = await _store.find(_db, finder: finder);
      int totalBytes = 0;
      for (final record in records) {
        final data = record['encryptedData'] as Uint8List?;
        if (data != null) totalBytes += data.lengthInBytes;
      }
      _logger.debug('[LocalFileCache] Cache size: $totalBytes bytes');
      return totalBytes;
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] Error getting cache size',
        error: e,
        stackTrace: stack,
      );
      return 0;
    }
  }

  Future<List<String>> getCachedFileIds() async {
    _logger.debug('[LocalFileCache] getCachedFileIds called');
    await _init();
    try {
      final keys = await _store.findKeys(_db);
      return keys.map((k) => k.toString()).toList();
    } catch (e, stack) {
      _logger.error(
        '[LocalFileCache] Error getting cached file IDs',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }
}
