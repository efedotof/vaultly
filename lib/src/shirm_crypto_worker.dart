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

  final errorPtrPtr = calloc<Pointer<Char>>();
  final stream = bindings.shirm_encrypt_stream_init(
    request.inputPath.toNativeUtf8().cast<Char>(),
    request.publicKeyPem.toNativeUtf8().cast<Char>(),
    request.privateKeyPem?.toNativeUtf8().cast<Char>() ?? nullptr.cast(),
    request.userId.toNativeUtf8().cast<Char>(),
    request.keyOwner.toNativeUtf8().cast<Char>(),
    (request.originalFileName ?? '').toNativeUtf8().cast<Char>(),
    request.compress ? 1 : 0,
    nullptr,
    nullptr,
    errorPtrPtr,
  );

  if (stream == nullptr) {
    final errorPtr = errorPtrPtr.value;
    final error = errorPtr == nullptr
        ? 'Unknown error'
        : errorPtr.cast<Utf8>().toDartString();
    sendPort.send({'error': error});
    calloc.free(errorPtrPtr);
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
      if (result == 0) break; 
      if (result < 0) {
        final errorPtr = errorPtrPtr.value;
        final error = errorPtr == nullptr
            ? 'Processing error'
            : errorPtr.cast<Utf8>().toDartString();
        sendPort.send({'error': error});
        calloc.free(outChunkPtr);
        calloc.free(outChunkSizePtr);
        break;
      }
      final chunkPtr = outChunkPtr.value;
      final chunkSize = outChunkSizePtr.value;
      if (chunkPtr != nullptr && chunkSize > 0) {
        final data = chunkPtr.asTypedList(chunkSize);
        sendPort.send(Uint8List.fromList(data));
        calloc.free(chunkPtr);
      }
      calloc.free(outChunkPtr);
      calloc.free(outChunkSizePtr);
    }
    sendPort.send(null);
  } catch (e) {
    sendPort.send({'error': e.toString()});
  } finally {
    bindings.shirm_encrypt_stream_free(stream);
    calloc.free(errorPtrPtr);
  }
}

void decryptStreamIsolate(List<Object> args) {
  final request = args[0] as DecryptStreamRequest;
  final sendPort = args[1] as SendPort;

  final dylib = _loadLibrary();
  final bindings = ShirmCryptoBindings(dylib);

  final errorPtrPtr = calloc<Pointer<Char>>();

  final dataPtr = calloc<Uint8>(request.shpsData.length);
  final dataList = dataPtr.asTypedList(request.shpsData.length);
  dataList.setAll(0, request.shpsData);

  final stream = bindings.shirm_decrypt_stream_init(
    dataPtr,
    request.shpsData.length,
    request.privateKeyPem.toNativeUtf8().cast<Char>(),
    nullptr,
    nullptr,
    errorPtrPtr,
  );

  if (stream == nullptr) {
    final errorPtr = errorPtrPtr.value;
    final error = errorPtr == nullptr
        ? 'Unknown error'
        : errorPtr.cast<Utf8>().toDartString();
    sendPort.send({'error': error});
    calloc.free(dataPtr);
    calloc.free(errorPtrPtr);
    return;
  }

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
      if (result == 0) break;
      if (result < 0) {
        final errorPtr = errorPtrPtr.value;
        final error = errorPtr == nullptr
            ? 'Processing error'
            : errorPtr.cast<Utf8>().toDartString();
        sendPort.send({'error': error});
        calloc.free(outChunkPtr);
        calloc.free(outChunkSizePtr);
        break;
      }
      final chunkPtr = outChunkPtr.value;
      final chunkSize = outChunkSizePtr.value;
      if (chunkPtr != nullptr && chunkSize > 0) {
        final data = chunkPtr.asTypedList(chunkSize);
        sendPort.send(Uint8List.fromList(data));
        calloc.free(chunkPtr);
      }
      calloc.free(outChunkPtr);
      calloc.free(outChunkSizePtr);
    }
    sendPort.send(null);
  } catch (e) {
    sendPort.send({'error': e.toString()});
  } finally {
    bindings.shirm_decrypt_stream_free(stream);
    calloc.free(dataPtr);
    calloc.free(errorPtrPtr);
  }
}

DynamicLibrary _loadLibrary() {
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
}
