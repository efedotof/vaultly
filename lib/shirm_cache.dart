import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'shirm_crypto_bindings_generated.dart';

final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.process();
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('libshirm_crypto.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('shirm_crypto.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

class ShirmCache {
  final Pointer<Void> _cachePtr;
  static final _bindings = ShirmCryptoBindings(_dylib);

  ShirmCache._(this._cachePtr);

  static String _takeError(Pointer<Pointer<Char>> errorPtr) {
    final cstr = errorPtr.value;
    if (cstr == nullptr) return 'Unknown error';
    final msg = cstr.cast<Utf8>().toDartString();
    _bindings.shirm_free(cstr.cast<Void>());
    errorPtr.value = nullptr;
    return msg;
  }

  static Future<ShirmCache> init(String cacheDir) async {
    return using((arena) {
      final errorPtr = arena<Pointer<Utf8>>();
      final ptr = _bindings.shirm_cache_init(
        cacheDir.toNativeUtf8(allocator: arena).cast<Char>(),
        errorPtr.cast<Pointer<Char>>(),
      );
      if (ptr == nullptr) {
        throw Exception('Cache init failed: ${_takeError(errorPtr.cast())}');
      }
      return ShirmCache._(ptr);
    });
  }

  Future<void> save(
    String fileId,
    Uint8List data, {
    String? originalName,
  }) async {
    return using((arena) {
      final errorPtr = arena<Pointer<Utf8>>();
      final dataPtr = arena<Uint8>(data.length);
      dataPtr.asTypedList(data.length).setAll(0, data);
      final result = _bindings.shirm_cache_save(
        _cachePtr,
        fileId.toNativeUtf8(allocator: arena).cast<Char>(),
        dataPtr,
        data.length,
        originalName?.toNativeUtf8(allocator: arena).cast<Char>() ?? nullptr,
        errorPtr.cast<Pointer<Char>>(),
      );
      if (result == 0) {
        throw Exception(_takeError(errorPtr.cast()));
      }
    });
  }

  Future<Uint8List> load(String fileId) async {
    return using((arena) {
      final outSize = arena<Size>();
      final errorPtr = arena<Pointer<Utf8>>();
      final dataPtr = _bindings.shirm_cache_load(
        _cachePtr,
        fileId.toNativeUtf8(allocator: arena).cast<Char>(),
        outSize,
        errorPtr.cast<Pointer<Char>>(),
      );
      if (dataPtr == nullptr) {
        throw Exception(_takeError(errorPtr.cast()));
      }
      final size = outSize.value;
      final bytes = dataPtr.asTypedList(size);
      final result = Uint8List.fromList(bytes);
      _bindings.shirm_free(dataPtr.cast<Void>());
      return result;
    });
  }

  Future<bool> has(String fileId) async {
    return using((arena) {
      return _bindings.shirm_cache_has(
            _cachePtr,
            fileId.toNativeUtf8(allocator: arena).cast<Char>(),
          ) !=
          0;
    });
  }

  Future<void> delete(String fileId) async {
    return using((arena) {
      final errorPtr = arena<Pointer<Utf8>>();
      final result = _bindings.shirm_cache_delete(
        _cachePtr,
        fileId.toNativeUtf8(allocator: arena).cast<Char>(),
        errorPtr.cast<Pointer<Char>>(),
      );
      if (result == 0) {
        throw Exception(_takeError(errorPtr.cast()));
      }
    });
  }

  Future<void> clear() async {
    return using((arena) {
      final errorPtr = arena<Pointer<Utf8>>();
      final result = _bindings.shirm_cache_clear(
        _cachePtr,
        errorPtr.cast<Pointer<Char>>(),
      );
      if (result == 0) {
        throw Exception(_takeError(errorPtr.cast()));
      }
    });
  }

  Future<List<Map<String, dynamic>>> getAllMetadata() async {
    return using((arena) {
      final errorPtr = arena<Pointer<Utf8>>();
      final jsonPtr = _bindings.shirm_cache_get_all_metadata(
        _cachePtr,
        errorPtr.cast<Pointer<Char>>(),
      );
      if (jsonPtr == nullptr) {
        throw Exception(_takeError(errorPtr.cast()));
      }
      final jsonStr = jsonPtr.cast<Utf8>().toDartString();
      _bindings.shirm_free(jsonPtr.cast<Void>());
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      final files = decoded['files'] as List<dynamic>;
      return files.cast<Map<String, dynamic>>();
    });
  }

  void close() {
    _bindings.shirm_cache_close(_cachePtr);
  }

  Future<void> saveStream(
    String fileId,
    Stream<Uint8List> source, {
    String? originalName,
  }) async {
    final errorPtr = calloc<Pointer<Utf8>>();
    final saveStreamPtr = _bindings.shirm_cache_save_stream_init(
      _cachePtr,
      fileId.toNativeUtf8().cast<Char>(),
      (originalName ?? '').toNativeUtf8().cast<Char>(),
      errorPtr.cast<Pointer<Char>>(),
    );
    if (saveStreamPtr == nullptr) {
      throw Exception(_takeError(errorPtr.cast()));
    }
    try {
      await for (final chunk in source) {
        final arena = Arena();
        try {
          final chunkPtr = arena<Uint8>(chunk.length);
          chunkPtr.asTypedList(chunk.length).setAll(0, chunk);
          final r = _bindings.shirm_cache_save_stream_write(
            saveStreamPtr,
            chunkPtr,
            chunk.length,
            errorPtr.cast<Pointer<Char>>(),
          );
          if (r == 0) {
            throw Exception(_takeError(errorPtr.cast()));
          }
        } finally {
          arena.releaseAll();
        }
      }
      final r = _bindings.shirm_cache_save_stream_finish(
        saveStreamPtr,
        errorPtr.cast<Pointer<Char>>(),
      );
      if (r == 0) {
        throw Exception(_takeError(errorPtr.cast()));
      }
    } finally {
      _bindings.shirm_cache_save_stream_free(saveStreamPtr);
      calloc.free(errorPtr);
    }
  }

  Stream<Uint8List> loadStream(String fileId) async* {
    final errorPtr = calloc<Pointer<Utf8>>();
    final loadStreamPtr = _bindings.shirm_cache_load_stream_init(
      _cachePtr,
      fileId.toNativeUtf8().cast<Char>(),
      errorPtr.cast<Pointer<Char>>(),
    );
    if (loadStreamPtr == nullptr) {
      calloc.free(errorPtr);
      throw Exception(_takeError(errorPtr.cast()));
    }
    try {
      while (true) {
        final outChunkPtr = calloc<Pointer<Uint8>>();
        final outSizePtr = calloc<Size>();
        try {
          final r = _bindings.shirm_cache_load_stream_read(
            loadStreamPtr,
            outChunkPtr,
            outSizePtr,
            errorPtr.cast<Pointer<Char>>(),
          );
          if (r == 0) break;
          if (r < 0) {
            throw Exception(_takeError(errorPtr.cast()));
          }
          final chunkPtr = outChunkPtr.value;
          final chunkSize = outSizePtr.value;
          if (chunkPtr != nullptr && chunkSize > 0) {
            final data = Uint8List.fromList(
              chunkPtr.asTypedList(chunkSize),
            );
            _bindings.shirm_free(chunkPtr.cast<Void>());
            yield data;
          }
        } finally {
          calloc.free(outChunkPtr);
          calloc.free(outSizePtr);
        }
      }
    } finally {
      _bindings.shirm_cache_load_stream_free(loadStreamPtr);
      calloc.free(errorPtr);
    }
  }
}
