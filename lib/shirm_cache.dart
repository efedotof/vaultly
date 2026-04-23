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

  static Future<ShirmCache> init(String cacheDir) async {
    return using((arena) {
      final errorPtr = arena<Pointer<Utf8>>();
      final ptr = _bindings.shirm_cache_init(
        cacheDir.toNativeUtf8(allocator: arena).cast<Char>(),
        errorPtr.cast<Pointer<Char>>(),
      );
      if (ptr == nullptr) {
        final error = errorPtr.value.toDartString();
        throw Exception('Cache init failed: $error');
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
        final error = errorPtr.value.toDartString();
        throw Exception(error);
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
        final error = errorPtr.value.toDartString();
        throw Exception(error);
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
        final error = errorPtr.value.toDartString();
        throw Exception(error);
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
        final error = errorPtr.value.toDartString();
        throw Exception(error);
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
        final error = errorPtr.value.toDartString();
        throw Exception(error);
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
}
