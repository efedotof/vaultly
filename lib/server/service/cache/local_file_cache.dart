import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class LocalFileCache {
  static LocalFileCache? _instance;
  bool _initialized = false;
  late Directory _cacheDir;

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
    _cacheDir = Directory('${appDir.path}/shirm_cache_files');
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
    }
    _initialized = true;
  }

  Future<void> saveFile(
    String fileId,
    Uint8List data, {
    String? originalName,
  }) async {
    await _init();
    final file = File('${_cacheDir.path}/$fileId.dat');
    await file.writeAsBytes(data);
    await _saveMetadata(fileId, originalName, data.length);
    _memoryCache[fileId] = data;
  }

  Future<void> saveFileChunked(
    String fileId,
    Stream<Uint8List> dataStream, {
    String? originalName,
    int chunkSize = 1024 * 1024,
  }) async {
    await _init();
    final file = File('${_cacheDir.path}/$fileId.dat');
    final sink = file.openWrite();
    int totalSize = 0;
    await for (final chunk in dataStream) {
      sink.add(chunk);
      totalSize += chunk.length;
      if (totalSize % (5 * 1024 * 1024) == 0) {
        await Future.delayed(Duration.zero);
      }
    }
    await sink.flush();
    await sink.close();
    await _saveMetadata(fileId, originalName, totalSize);

    if (totalSize <= 10 * 1024 * 1024) {
      final data = await file.readAsBytes();
      _memoryCache[fileId] = data;
    } else {
      _memoryCache.remove(fileId);
    }
  }

  Future<void> _saveMetadata(
    String fileId,
    String? originalName,
    int size,
  ) async {
    final metaFile = File('${_cacheDir.path}/$fileId.meta.json');
    final meta = {
      'originalName': originalName,
      'size': size,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await metaFile.writeAsString(jsonEncode(meta));
  }

  Future<Map<String, dynamic>?> _loadMetadata(String fileId) async {
    final metaFile = File('${_cacheDir.path}/$fileId.meta.json');
    if (!await metaFile.exists()) return null;
    final content = await metaFile.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<Uint8List?> getFileDecrypted(String fileId) async {
    if (_memoryCache.containsKey(fileId)) return _memoryCache[fileId];
    if (_pendingFutures.containsKey(fileId)) return _pendingFutures[fileId];

    final future = _getFileDecryptedInternal(fileId);
    _pendingFutures[fileId] = future;
    try {
      final result = await future;
      if (result != null && result.length <= 10 * 1024 * 1024) {
        _memoryCache[fileId] = result;
      }
      return result;
    } finally {
      _pendingFutures.remove(fileId);
    }
  }

  Future<Uint8List?> _getFileDecryptedInternal(String fileId) async {
    await _init();
    final file = File('${_cacheDir.path}/$fileId.dat');
    if (!await file.exists()) return null;
    try {
      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  Stream<Uint8List> getFileStream(String fileId) async* {
    await _init();
    final file = File('${_cacheDir.path}/$fileId.dat');
    if (!await file.exists()) return;
    final stream = file.openRead();
    await for (final chunk in stream) {
      yield Uint8List.fromList(chunk);
    }
  }

  Future<bool> hasFile(String fileId) async {
    await _init();
    final file = File('${_cacheDir.path}/$fileId.dat');
    return await file.exists();
  }

  Future<String?> getOriginalName(String fileId) async {
    await _init();
    final meta = await _loadMetadata(fileId);
    return meta?['originalName'] as String?;
  }

  Future<void> deleteFile(String fileId) async {
    await _init();
    final file = File('${_cacheDir.path}/$fileId.dat');
    final metaFile = File('${_cacheDir.path}/$fileId.meta.json');
    await file.delete(recursive: true);
    await metaFile.delete(recursive: true);
    _memoryCache.remove(fileId);
  }

  Future<void> clearCache() async {
    await _init();
    await _cacheDir.delete(recursive: true);
    await _cacheDir.create();
    _memoryCache.clear();
  }

  Future<int> getCacheSize() async {
    await _init();
    int total = 0;
    final files = await _cacheDir.list().toList();
    for (final entity in files) {
      if (entity is File && entity.path.endsWith('.dat')) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<List<String>> getCachedFileIds() async {
    await _init();
    final List<String> ids = [];
    final files = await _cacheDir.list().toList();
    for (final entity in files) {
      if (entity is File && entity.path.endsWith('.dat')) {
        final id = entity.path.split('/').last.replaceAll('.dat', '');
        ids.add(id);
      }
    }
    return ids;
  }

  Future<List<Map<String, dynamic>>> getAllCachedFileMetadata() async {
    await _init();
    final List<Map<String, dynamic>> result = [];
    final files = await _cacheDir.list().toList();
    for (final entity in files) {
      if (entity is File && entity.path.endsWith('.meta.json')) {
        final content = await entity.readAsString();
        final meta = jsonDecode(content) as Map<String, dynamic>;
        final fileId = entity.path.split('/').last.replaceAll('.meta.json', '');
        result.add({
          'id': fileId,
          'originalName': meta['originalName'],
          'timestamp': DateTime.parse(meta['createdAt']).millisecondsSinceEpoch,
          'size': meta['size'],
        });
      }
    }
    return result;
  }

  Future<void> close() async {
    _memoryCache.clear();
    _initialized = false;
  }

  void saveFileInBackground({
    required String fileId,
    required Uint8List data,
    String? originalName,
  }) {
    saveFile(fileId, data, originalName: originalName).catchError((_) {});
  }
}
