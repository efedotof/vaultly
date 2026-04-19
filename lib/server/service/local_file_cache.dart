import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:vaulth_app/storage/secure_storage_adapter.dart';
import 'package:webcrypto/webcrypto.dart' as web;
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/api.dart' show AEADParameters, KeyParameter;

Future<Uint8List> _decryptInIsolate(Map<String, dynamic> args) async {
  try {
    final Uint8List encryptedData = args['encryptedData'] as Uint8List;
    final Uint8List key = args['key'] as Uint8List;
    final Uint8List nonce = args['nonce'] as Uint8List;

    final keyParam = KeyParameter(key);
    final gcm = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(keyParam, 128, nonce, Uint8List(0)));
    final plaintext = Uint8List(gcm.getOutputSize(encryptedData.length));
    final processed = gcm.processBytes(
      encryptedData,
      0,
      encryptedData.length,
      plaintext,
      0,
    );
    final finalised = gcm.doFinal(plaintext, processed);
    final total = processed + finalised;
    return Uint8List.sublistView(plaintext, 0, total);
  } catch (e) {
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> _readMetadataInIsolate(String dbPath) async {
  try {
    final factory = databaseFactoryIo;
    final db = await factory.openDatabase(dbPath);
    final store = StoreRef.main();
    final records = await store.find(db, finder: Finder());
    final result = records.map((record) {
      return {
        'id': record['id'] as String,
        'originalName': record['originalName'] as String? ?? '',
        'timestamp': record['timestamp'] as int? ?? 0,
      };
    }).toList();
    await db.close();
    return result;
  } catch (e) {
    return [];
  }
}

Future<void> _saveToCacheIsolate(Map<String, dynamic> args) async {
  final fileId = args['fileId'] as String;
  final data = args['data'] as Uint8List;
  final originalName = args['originalName'] as String?;
  final dbPath = args['dbPath'] as String;

  final factory = databaseFactoryIo;
  final db = await factory.openDatabase(dbPath);
  final store = StoreRef<String, Map<String, dynamic>>.main();

  final random = Random.secure();
  final key = Uint8List(32);
  final nonce = Uint8List(12);
  for (int i = 0; i < 32; i++) {
    key[i] = random.nextInt(256);
  }
  for (int i = 0; i < 12; i++) {
    nonce[i] = random.nextInt(256);
  }

  final keyParam = KeyParameter(key);
  final gcm = GCMBlockCipher(AESEngine())
    ..init(true, AEADParameters(keyParam, 128, nonce, Uint8List(0)));
  final ciphertext = Uint8List(gcm.getOutputSize(data.length));
  final processed = gcm.processBytes(data, 0, data.length, ciphertext, 0);
  final finalised = gcm.doFinal(ciphertext, processed);
  final encryptedData = Uint8List.sublistView(
    ciphertext,
    0,
    processed + finalised,
  );

  final record = {
    'id': fileId,
    'encryptedData': encryptedData,
    'nonce': nonce,
    'encryptionKey': key,
    'originalName': originalName ?? '',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };

  await store.record(fileId).put(db, record);
  await db.close();
}

class LocalFileCache {
  late final Database _db;
  late final StoreRef<String, Map<String, dynamic>> _store;
  bool _initialized = false;
  String? _dbPath;
  Future<void>? _initFuture;

  static const String _keyPrefix = 'cache_key_';

  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, Future<Uint8List?>> _pendingFutures = {};

  static final _isolateSemaphore = Semaphore(2);

  Future<void> _init() async {
    if (_initialized) return;
    if (_initFuture != null) return _initFuture!;
    _initFuture = _doInit();
    await _initFuture;
  }

  Future<void> _doInit() async {
    try {
      final factory = kIsWeb ? databaseFactoryWeb : databaseFactoryIo;
      String dbPath;
      if (kIsWeb) {
        dbPath = 'file_cache.db';
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        dbPath = '${appDir.path}/file_cache.db';
      }
      _dbPath = dbPath;
      _db = await factory.openDatabase(dbPath);
      _store = StoreRef.main();
      _initialized = true;
    } catch (e) {
      _initFuture = null;
      rethrow;
    }
  }

  void saveFileInBackground({
    required String fileId,
    required Uint8List data,
    String? originalName,
  }) {
    if (_dbPath == null) {
      return;
    }
    compute(_saveToCacheIsolate, {
      'fileId': fileId,
      'data': data,
      'originalName': originalName,
      'dbPath': _dbPath,
    }).catchError((_) {});
  }

  Future<void> saveFileEncrypted({
    required String fileId,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List encryptedData,
    String? originalName,
  }) async {
    await _init();
    final record = {
      'id': fileId,
      'encryptedData': encryptedData,
      'nonce': nonce,
      'encryptionKey': key,
      'originalName': originalName ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _store.record(fileId).put(_db, record);
  }

  Future<void> saveFile(
    String fileId,
    Uint8List data, {
    String? originalName,
  }) async {
    await _init();
    final (key, nonce) = _generateKeyAndNonce();
    final encryptedData = await _aesGcmEncrypt(data, key, nonce);
    await _saveFileKey(fileId, key);
    final record = {
      'id': fileId,
      'encryptedData': encryptedData,
      'nonce': nonce,
      'originalName': originalName ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _store.record(fileId).put(_db, record);
    _memoryCache[fileId] = data;
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
    } catch (_) {}
  }

  Future<Uint8List?> _getFileKey(String fileId) async {
    try {
      final b64 = await SecureStorageAdapter.read(key: '$_keyPrefix$fileId');
      if (b64 == null || b64.isEmpty) return null;
      return base64Decode(b64);
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List> _aesGcmEncrypt(
    Uint8List plaintext,
    Uint8List key,
    Uint8List nonce,
  ) async {
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
      return Uint8List.sublistView(ciphertext, 0, processed + finalised);
    }
  }

  Future<Uint8List?> getFileDecrypted(String fileId) async {
    if (_memoryCache.containsKey(fileId)) return _memoryCache[fileId];
    if (_pendingFutures.containsKey(fileId)) return _pendingFutures[fileId];
    final future = _getFileDecryptedInternal(fileId);
    _pendingFutures[fileId] = future;
    try {
      final result = await future;
      if (result != null) _memoryCache[fileId] = result;
      return result;
    } finally {
      _pendingFutures.remove(fileId);
    }
  }

  Future<Uint8List?> _getFileDecryptedInternal(String fileId) async {
    await _init();
    try {
      final record = await _store.record(fileId).get(_db);
      if (record == null) return null;

      final encryptedData = record['encryptedData'] as Uint8List?;
      final nonce = record['nonce'] as Uint8List?;
      Uint8List? key = await _getFileKey(fileId);
      key ??= record['encryptionKey'] as Uint8List?;

      if (encryptedData == null || nonce == null || key == null) return null;

      if (kIsWeb) {
        return await _aesGcmDecrypt(encryptedData, key, nonce);
      } else {
        return await _isolateSemaphore.withPermit(
          () => compute(_decryptInIsolate, {
            'encryptedData': encryptedData,
            'key': key,
            'nonce': nonce,
          }),
        );
      }
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List> _aesGcmDecrypt(
    Uint8List ciphertext,
    Uint8List key,
    Uint8List nonce,
  ) async {
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
      return Uint8List.sublistView(plaintext, 0, processed + finalised);
    }
  }

  Future<bool> hasFile(String fileId) async {
    await _init();
    try {
      final snapshot = await _store.record(fileId).getSnapshot(_db);
      return snapshot != null;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getOriginalName(String fileId) async {
    await _init();
    try {
      final record = await _store.record(fileId).get(_db);
      return record?['originalName'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteFile(String fileId) async {
    await _init();
    try {
      await _store.record(fileId).delete(_db);
      await _deleteFileKey(fileId);
      _memoryCache.remove(fileId);
    } catch (_) {}
  }

  Future<void> _deleteFileKey(String fileId) async {
    try {
      await SecureStorageAdapter.delete(key: '$_keyPrefix$fileId');
    } catch (_) {}
  }

  Future<void> clearCache() async {
    await _init();
    try {
      final keys = await _store.findKeys(_db);
      for (final key in keys) {
        await _deleteFileKey(key.toString());
      }
      await _store.drop(_db);
      _memoryCache.clear();
    } catch (_) {}
  }

  Future<int> getCacheSize() async {
    await _init();
    try {
      final records = await _store.find(_db, finder: Finder());
      int total = 0;
      for (final r in records) {
        final data = r['encryptedData'];
        if (data is Uint8List) {
          total += data.length;
        } else if (data is List<int>) {
          total += data.length;
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<List<String>> getCachedFileIds() async {
    await _init();
    try {
      final keys = await _store.findKeys(_db);
      return keys.map((k) => k.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllCachedFileMetadata() async {
    await _init();
    try {
      if (kIsWeb) {
        final records = await _store.find(_db, finder: Finder());
        return records
            .map(
              (r) => {
                'id': r['id'] as String,
                'originalName': r['originalName'] as String? ?? '',
                'timestamp': r['timestamp'] as int? ?? 0,
              },
            )
            .toList();
      } else {
        if (_dbPath == null) return [];
        return await compute(_readMetadataInIsolate, _dbPath!);
      }
    } catch (_) {
      return [];
    }
  }
}

class Semaphore {
  final int maxPermits;
  int _permits;
  final List<Completer<void>> _waiters = [];

  Semaphore(this.maxPermits) : _permits = maxPermits;

  Future<T> withPermit<T>(Future<T> Function() action) async {
    await acquire();
    try {
      return await action();
    } finally {
      release();
    }
  }

  Future<void> acquire() async {
    if (_permits > 0) {
      _permits--;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      final completer = _waiters.removeAt(0);
      completer.complete();
    } else {
      _permits++;
    }
  }
}
