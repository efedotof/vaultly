import 'dart:async';
import 'dart:typed_data';
import 'package:sembast_web/sembast_web.dart';

class LocalFileCache {
  static LocalFileCache? _instance;
  late Database _db;
  late StoreRef<String, Map<String, dynamic>> _metaStore;
  late StoreRef<String, Uint8List> _chunksStore;
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
    _chunksStore = StoreRef<String, Uint8List>('chunks');
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

    await for (final chunk in _chunkStream(dataStream, chunkSize)) {
      final key = '${fileId}_$chunkIndex';
      await _chunksStore.record(key).put(_db, chunk);
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

  Stream<Uint8List> getFileChunksStream(String fileId) async* {
    await _init();
    final meta = await _metaStore.record(fileId).get(_db);
    if (meta == null) return;
    final chunkCount = meta['chunkCount'] as int;
    for (int i = 0; i < chunkCount; i++) {
      final key = '${fileId}_$i';
      final chunk = await _chunksStore.record(key).get(_db);
      if (chunk != null) yield chunk;
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

  Future<void> saveFile(
    String fileId,
    Uint8List data, {
    String? originalName,
  }) async {
    await saveFileChunked(
      fileId,
      Stream.value(data),
      originalName: originalName,
    );
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

  Stream<Uint8List> _chunkStream(
    Stream<Uint8List> stream,
    int chunkSize,
  ) async* {
    List<int> buffer = [];
    await for (final data in stream) {
      buffer.addAll(data);
      while (buffer.length >= chunkSize) {
        yield Uint8List.fromList(buffer.sublist(0, chunkSize));
        buffer = buffer.sublist(chunkSize);
      }
    }
    if (buffer.isNotEmpty) yield Uint8List.fromList(buffer);
  }

  Future<void> close() async {
    if (_initialized) await _db.close();
  }
}
