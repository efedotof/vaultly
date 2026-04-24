import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shirm_crypto/shirm_cache.dart';

class LocalFileCache {
  static LocalFileCache? _instance;
  late final ShirmCache _cache;
  bool _initialized = false;
  String? _cacheDir;

  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, Future<Uint8List?>> _pendingFutures = {};

  static LocalFileCache get instance {
    _instance ??= LocalFileCache._();
    return _instance!;
  }

  LocalFileCache._();

  Future<void> _init() async {
    if (_initialized) return;
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = '${appDir.path}/shirm_cache';
    _cache = await ShirmCache.init(_cacheDir!);
    _initialized = true;
  }

  void saveFileInBackground({
    required String fileId,
    required Uint8List data,
    String? originalName,
  }) {
    saveFile(fileId, data, originalName: originalName).catchError((_) {});
  }

  @Deprecated('Use saveFile instead, encryption is handled internally')
  Future<void> saveFileEncrypted({
    required String fileId,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List encryptedData,
    String? originalName,
  }) async {
    throw UnimplementedError(
      'saveFileEncrypted is deprecated. Use saveFile with plain data.',
    );
  }

  Future<void> saveFile(
    String fileId,
    Uint8List data, {
    String? originalName,
  }) async {
    await _init();
    await _cache.save(fileId, data, originalName: originalName);
    _memoryCache[fileId] = data;
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
      final result = await _cache.load(fileId);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasFile(String fileId) async {
    await _init();
    return _cache.has(fileId);
  }

  Future<String?> getOriginalName(String fileId) async {
    await _init();
    final all = await _cache.getAllMetadata();
    return all.firstWhere(
          (m) => m['id'] == fileId,
          orElse: () => {},
        )['originalName']
        as String?;
  }

  Future<void> deleteFile(String fileId) async {
    await _init();
    await _cache.delete(fileId);
    _memoryCache.remove(fileId);
  }

  Future<void> clearCache() async {
    await _init();
    await _cache.clear();
    _memoryCache.clear();
  }

  Future<int> getCacheSize() async {
    await _init();
    final all = await _cache.getAllMetadata();
    int total = 0;
    for (final meta in all) {
      final id = meta['id'] as String;
      final file = File('$_cacheDir/$id.enc');
      if (await file.exists()) {
        total += await file.length();
      }
    }
    return total;
  }

  Future<List<String>> getCachedFileIds() async {
    await _init();
    final all = await _cache.getAllMetadata();
    return all.map((m) => m['id'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getAllCachedFileMetadata() async {
    await _init();
    return await _cache.getAllMetadata();
  }

  Future<void> close() async {
    if (_initialized) {
      _cache.close();
      _initialized = false;
    }
  }

  Future<void> saveFileChunked(
  String fileId,
  Stream<Uint8List> dataStream, {
  String? originalName,
  int chunkSize = 1024 * 1024,
}) async {
  await _init();
  final chunks = <Uint8List>[];
  await for (final chunk in dataStream) {
    chunks.add(chunk);
  }
  final totalLen = chunks.fold(0, (s, c) => s + c.length);
  final data = Uint8List(totalLen);
  int offset = 0;
  for (final chunk in chunks) {
    data.setAll(offset, chunk);
    offset += chunk.length;
  }
  await saveFile(fileId, data, originalName: originalName);
}
}
