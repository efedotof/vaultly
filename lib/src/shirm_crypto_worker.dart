import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:shirm_crypto/shirm_crypto_bindings_generated.dart';

class EncryptStreamRequest {
  final String inputPath;
  final String publicKeyPem;
  final String? privateKeyPem;
  final String userId;
  final String keyOwner;
  final String? originalFileName;
  final bool compress;
  EncryptStreamRequest({
    required this.inputPath,
    required this.publicKeyPem,
    this.privateKeyPem,
    required this.userId,
    required this.keyOwner,
    this.originalFileName,
    this.compress = false,
  });
}

class DecryptStreamRequest {
  final Uint8List shpsData;
  final String privateKeyPem;
  DecryptStreamRequest({required this.shpsData, required this.privateKeyPem});
}

void encryptStreamIsolate(List<Object> args) {
  final request = args[0] as EncryptStreamRequest;
  final sendPort = args[1] as SendPort;

  final dylib = _loadLibrary();
  final bindings = ShirmCryptoBindings(dylib);

  // Одноразовые строки — в Arena, освободятся все разом в finally.
  final arena = Arena();
  // Per-iteration скрэтч и errorPtrPtr — через calloc, чтобы можно было
  // освободить по ходу и не раздувать Arena в цикле.
  final errorPtrPtr = calloc<Pointer<Char>>();
  Pointer<ShirmEncryptStream>? stream;

  try {
    final inputPathPtr =
        request.inputPath.toNativeUtf8(allocator: arena).cast<Char>();
    final publicKeyPtr =
        request.publicKeyPem.toNativeUtf8(allocator: arena).cast<Char>();
    final privateKeyPtr =
        request.privateKeyPem?.toNativeUtf8(allocator: arena).cast<Char>() ??
            nullptr.cast<Char>();
    final userIdPtr =
        request.userId.toNativeUtf8(allocator: arena).cast<Char>();
    final keyOwnerPtr =
        request.keyOwner.toNativeUtf8(allocator: arena).cast<Char>();
    final origNamePtr = (request.originalFileName ?? '')
        .toNativeUtf8(allocator: arena)
        .cast<Char>();

    stream = bindings.shirm_encrypt_stream_init(
      inputPathPtr,
      publicKeyPtr,
      privateKeyPtr,
      userIdPtr,
      keyOwnerPtr,
      origNamePtr,
      request.compress ? 1 : 0,
      nullptr,
      nullptr,
      errorPtrPtr,
    );

    if (stream == nullptr) {
      _sendErrorAndFree(errorPtrPtr, sendPort);
      return;
    }

    try {
      while (true) {
        final outChunkPtr = calloc<Pointer<Uint8>>();
        final outChunkSizePtr = calloc<Size>();
        final result = bindings.shirm_encrypt_stream_process(
          stream,
          outChunkPtr,
          outChunkSizePtr,
          errorPtrPtr,
        );

        if (result == 0) {
          calloc.free(outChunkPtr);
          calloc.free(outChunkSizePtr);
          break;
        }
        if (result < 0) {
          calloc.free(outChunkPtr);
          calloc.free(outChunkSizePtr);
          _sendErrorAndFree(errorPtrPtr, sendPort,
              fallback: 'Processing error');
          sendPort.send(null);
          return;
        }

        final chunkPtr = outChunkPtr.value;
        final chunkSize = outChunkSizePtr.value;
        calloc.free(outChunkPtr);
        calloc.free(outChunkSizePtr);

        if (chunkPtr != nullptr && chunkSize > 0) {
          final data = chunkPtr.asTypedList(chunkSize);
          sendPort.send(Uint8List.fromList(data));
          // chunkPtr выделен C-шным malloc → освобождаем через C free.
          calloc.free(chunkPtr);
        }
      }
      sendPort.send(null);
    } finally {
      bindings.shirm_encrypt_stream_free(stream);
    }
  } catch (e) {
    sendPort.send({'error': e.toString()});
  } finally {
    calloc.free(errorPtrPtr);
    arena.releaseAll();
  }
}

void decryptStreamIsolate(List<Object> args) {
  final request = args[0] as DecryptStreamRequest;
  final sendPort = args[1] as SendPort;

  final dylib = _loadLibrary();
  final bindings = ShirmCryptoBindings(dylib);

  final arena = Arena();
  final errorPtrPtr = calloc<Pointer<Char>>();
  Pointer<Uint8>? dataPtr;
  Pointer<ShirmDecryptStream>? stream;

  try {
    final privateKeyPtr =
        request.privateKeyPem.toNativeUtf8(allocator: arena).cast<Char>();

    // Входной буфер — не в Arena, чтобы освободить сразу после init.
    dataPtr = calloc<Uint8>(request.shpsData.length);
    dataPtr.asTypedList(request.shpsData.length).setAll(0, request.shpsData);

    stream = bindings.shirm_decrypt_stream_init(
      dataPtr,
      request.shpsData.length,
      privateKeyPtr,
      nullptr,
      nullptr,
      errorPtrPtr,
    );

    if (stream == nullptr) {
      _sendErrorAndFree(errorPtrPtr, sendPort);
      return;
    }

    // init уже скопировал всё, что нужно (парсинг заголовка + EVP init).
    // Дальше dataPtr не нужен — освобождаем.
    calloc.free(dataPtr);
    dataPtr = nullptr;

    try {
      while (true) {
        final outChunkPtr = calloc<Pointer<Uint8>>();
        final outChunkSizePtr = calloc<Size>();
        final result = bindings.shirm_decrypt_stream_process(
          stream,
          outChunkPtr,
          outChunkSizePtr,
          errorPtrPtr,
        );

        if (result == 0) {
          calloc.free(outChunkPtr);
          calloc.free(outChunkSizePtr);
          break;
        }
        if (result < 0) {
          calloc.free(outChunkPtr);
          calloc.free(outChunkSizePtr);
          _sendErrorAndFree(errorPtrPtr, sendPort,
              fallback: 'Processing error');
          sendPort.send(null);
          return;
        }

        final chunkPtr = outChunkPtr.value;
        final chunkSize = outChunkSizePtr.value;
        calloc.free(outChunkPtr);
        calloc.free(outChunkSizePtr);

        if (chunkPtr != nullptr && chunkSize > 0) {
          final data = chunkPtr.asTypedList(chunkSize);
          sendPort.send(Uint8List.fromList(data));
          calloc.free(chunkPtr);
        }
      }
      sendPort.send(null);
    } finally {
      bindings.shirm_decrypt_stream_free(stream);
    }
  } catch (e) {
    sendPort.send({'error': e.toString()});
  } finally {
    if (dataPtr != null) calloc.free(dataPtr);
    calloc.free(errorPtrPtr);
    arena.releaseAll();
  }
}

/// Читает *errorPtrPtr, освобождает C-строку (её аллоцировал strdup в C),
/// освобождает сам errorPtrPtr и отправляет ошибку в SendPort.
void _sendErrorAndFree(
  Pointer<Pointer<Char>> errorPtrPtr,
  SendPort sendPort, {
  String fallback = 'Unknown error',
}) {
  final errorPtr = errorPtrPtr.value;
  if (errorPtr == nullptr) {
    sendPort.send({'error': fallback});
    return;
  }
  final msg = errorPtr.cast<Utf8>().toDartString();
  calloc.free(errorPtr); // strdup() внутри C
  sendPort.send({'error': msg});
}

DynamicLibrary _loadLibrary() {
  if (Platform.isMacOS || Platform.isIOS) return DynamicLibrary.process();
  if (Platform.isAndroid || Platform.isLinux)
    return DynamicLibrary.open('libshirm_crypto.so');
  if (Platform.isWindows) return DynamicLibrary.open('shirm_crypto.dll');
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}
