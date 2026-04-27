import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:sembast_web/sembast_web.dart';

class LocalFileCache {
  static LocalFileCache? _instance;
  late Database _db;
  late StoreRef<String, Map<String, dynamic>> _metaStore;
  late StoreRef<String, String> _chunksStore;
  bool _initialized = false;

  static LocalFileCache get instance {
    _instance ??= LocalFileCache._();
    return _instance!;
  }

  LocalFileCache._();

  Future<void> _init() async {
    if (_initialized) return;
    final factory = databaseFactoryWeb;
    _db = await factory.openDatabase('shirm_cache_web');
    _metaStore = StoreRef<String, Map<String, dynamic>>('metadata');
    _chunksStore = StoreRef<String, String>('chunks_base64');
    _initialized = true;
  }

  Future<void> saveFileChunked(
    String fileId,
    Stream<Uint8List> dataStream, {
    String? originalName,
    int chunkSize = 1024 * 1024,
  }) async {
    await _init();
    int chunkIndex = 0;
    int totalSize = 0;
    final List<int> chunkSizes = [];

    await for (final chunk in dataStream) {
      final base64 = base64Encode(chunk);
      final key = '${fileId}_$chunkIndex';
      await _chunksStore.record(key).put(_db, base64);
      chunkSizes.add(chunk.length);
      totalSize += chunk.length;
      chunkIndex++;
    }

    await _metaStore.record(fileId).put(_db, {
      'originalName': originalName,
      'totalSize': totalSize,
      'chunkSize': chunkSize,
      'chunkCount': chunkIndex,
      'chunkSizes': chunkSizes,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveFile(
    String fileId,
    Uint8List data, {
    String? originalName,
  }) async {
    await _init();
    final base64 = base64Encode(data);
    final key = '${fileId}_0';
    await _chunksStore.record(key).put(_db, base64);
    await _metaStore.record(fileId).put(_db, {
      'originalName': originalName,
      'totalSize': data.length,
      'chunkSize': data.length,
      'chunkCount': 1,
      'chunkSizes': [data.length],
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<Uint8List> getFileChunksStream(String fileId) async* {
    await _init();
    final meta = await _metaStore.record(fileId).get(_db);
    if (meta == null) return;
    final chunkCount = meta['chunkCount'] as int;
    for (int i = 0; i < chunkCount; i++) {
      final key = '${fileId}_$i';
      final base64 = await _chunksStore.record(key).get(_db);
      if (base64 != null) {
        yield base64Decode(base64);
      }
    }
  }

  Future<Uint8List?> getFileDecrypted(String fileId) async {
    final chunks = <Uint8List>[];
    await for (final chunk in getFileChunksStream(fileId)) {
      chunks.add(chunk);
    }
    if (chunks.isEmpty) return null;
    final totalLen = chunks.fold(0, (sum, c) => sum + c.length);
    final result = Uint8List(totalLen);
    int offset = 0;
    for (final chunk in chunks) {
      result.setAll(offset, chunk);
      offset += chunk.length;
    }
    return result;
  }

  Future<bool> hasFile(String fileId) async {
    await _init();
    return await _metaStore.record(fileId).get(_db) != null;
  }

  Future<void> deleteFile(String fileId) async {
    await _init();
    final meta = await _metaStore.record(fileId).get(_db);
    if (meta != null) {
      final chunkCount = meta['chunkCount'] as int;
      for (int i = 0; i < chunkCount; i++) {
        await _chunksStore.record('${fileId}_$i').delete(_db);
      }
      await _metaStore.record(fileId).delete(_db);
    }
  }

  Future<void> clearCache() async {
    await _init();
    await _metaStore.delete(_db);
    await _chunksStore.delete(_db);
  }

  Future<List<Map<String, dynamic>>> getAllCachedFileMetadata() async {
    await _init();
    final finder = Finder(sortOrders: [SortOrder('createdAt')]);
    final records = await _metaStore.find(_db, finder: finder);
    return records.map((record) {
      final meta = record.value;
      final createdAt = DateTime.parse(meta['createdAt'] as String);
      return {
        'id': record.key,
        'originalName': meta['originalName'],
        'timestamp': createdAt.millisecondsSinceEpoch,
        'totalSize': meta['totalSize'],
        'chunkCount': meta['chunkCount'],
      };
    }).toList();
  }

  Future<String?> getOriginalName(String fileId) async {
    await _init();
    final meta = await _metaStore.record(fileId).get(_db);
    return meta?['originalName'] as String?;
  }

  Future<void> close() async {
    if (_initialized) await _db.close();
  }

  void saveFileInBackground({
    required String fileId,
    required Uint8List data,
    String? originalName,
  }) {
    saveFile(fileId, data, originalName: originalName).catchError((_) {});
  }

  Future<int> getCacheSize() async {
    await _init();
    int total = 0;
    final records = await _metaStore.find(_db, finder: Finder());
    for (final record in records) {
      final meta = record.value;
      total += (meta['totalSize'] as int?) ?? 0;
    }
    return total;
  }
}
