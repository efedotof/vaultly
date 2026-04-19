import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'shirm_crypto_bindings_generated.dart';
import 'src/shirm_crypto_worker.dart' as worker;

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

final _bindings = ShirmCryptoBindings(_dylib);

class ShirmCrypto {
  static Future<Uint8List> encryptFile({
    required String inputPath,
    required String publicKeyPem,
    String? privateKeyPem,
    required String userId,
    required String keyOwner,
    String? originalFileName,
    bool compress = false,
  }) async {
    return using((Arena arena) {
      final resultPtr = _bindings.shirm_encrypt_file(
        inputPath.toNativeUtf8(allocator: arena).cast<Char>(),
        publicKeyPem.toNativeUtf8(allocator: arena).cast<Char>(),
        privateKeyPem?.toNativeUtf8(allocator: arena).cast<Char>() ??
            nullptr.cast(),
        userId.toNativeUtf8(allocator: arena).cast<Char>(),
        keyOwner.toNativeUtf8(allocator: arena).cast<Char>(),
        (originalFileName ?? '').toNativeUtf8(allocator: arena).cast<Char>(),
        compress ? 1 : 0,
        nullptr,
        nullptr,
      );

      final result = resultPtr.ref;
      if (result.error != nullptr) {
        final error = result.error.cast<Utf8>().toDartString();
        _bindings.shirm_free_encrypt_result(resultPtr);
        throw Exception(error);
      }

      final data = result.data.asTypedList(result.size);
      final copy = Uint8List.fromList(data);
      _bindings.shirm_free_encrypt_result(resultPtr);
      return copy;
    });
  }

  static Future<Uint8List> decryptData({
    required Uint8List shpsData,
    required String privateKeyPem,
  }) async {
    return using((Arena arena) {
      final dataPtr = arena<Uint8>(shpsData.length);
      dataPtr.asTypedList(shpsData.length).setAll(0, shpsData);

      final resultPtr = _bindings.shirm_decrypt_data(
        dataPtr,
        shpsData.length,
        privateKeyPem.toNativeUtf8(allocator: arena).cast<Char>(),
        nullptr,
        nullptr,
      );

      final result = resultPtr.ref;
      if (result.error != nullptr) {
        final error = result.error.cast<Utf8>().toDartString();
        _bindings.shirm_free_decrypt_result(resultPtr);
        throw Exception(error);
      }

      final data = result.data.asTypedList(result.size);
      final copy = Uint8List.fromList(data);
      _bindings.shirm_free_decrypt_result(resultPtr);
      return copy;
    });
  }

  static Stream<Uint8List> encryptFileStream({
    required String inputPath,
    required String publicKeyPem,
    String? privateKeyPem,
    required String userId,
    required String keyOwner,
    String? originalFileName,
    bool compress = false,
  }) {
    final controller = StreamController<Uint8List>();
    final receivePort = ReceivePort();

    final request = worker.EncryptStreamRequest(
      inputPath: inputPath,
      publicKeyPem: publicKeyPem,
      privateKeyPem: privateKeyPem,
      userId: userId,
      keyOwner: keyOwner,
      originalFileName: originalFileName,
      compress: compress,
    );

    Isolate.spawn(worker.encryptStreamIsolate, [request, receivePort.sendPort]);

    receivePort.listen((message) {
      if (message == null) {
        controller.close();
        receivePort.close();
      } else if (message is Uint8List) {
        controller.add(message);
      } else if (message is Map && message.containsKey('error')) {
        controller.addError(Exception(message['error']));
        controller.close();
        receivePort.close();
      }
    });

    return controller.stream;
  }

  static Stream<Uint8List> decryptDataStream({
    required Uint8List shpsData,
    required String privateKeyPem,
  }) {
    final controller = StreamController<Uint8List>();
    final receivePort = ReceivePort();

    final request = worker.DecryptStreamRequest(
      shpsData: shpsData,
      privateKeyPem: privateKeyPem,
    );

    Isolate.spawn(worker.decryptStreamIsolate, [request, receivePort.sendPort]);

    receivePort.listen((message) {
      if (message == null) {
        controller.close();
        receivePort.close();
      } else if (message is Uint8List) {
        controller.add(message);
      } else if (message is Map && message.containsKey('error')) {
        controller.addError(Exception(message['error']));
        controller.close();
        receivePort.close();
      }
    });

    return controller.stream;
  }

  static Future<void> encryptFileToFile({
    required String inputPath,
    required String outputPath,
    required String publicKeyPem,
    String? privateKeyPem,
    required String userId,
    required String keyOwner,
    String? originalFileName,
    bool compress = false,
  }) async {
    final file = File(outputPath);
    final sink = file.openWrite();
    try {
      await for (final chunk in encryptFileStream(
        inputPath: inputPath,
        publicKeyPem: publicKeyPem,
        privateKeyPem: privateKeyPem,
        userId: userId,
        keyOwner: keyOwner,
        originalFileName: originalFileName,
        compress: compress,
      )) {
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
  }

  static Future<void> decryptDataToFile({
    required Uint8List shpsData,
    required String outputPath,
    required String privateKeyPem,
  }) async {
    final file = File(outputPath);
    final sink = file.openWrite();
    try {
      await for (final chunk in decryptDataStream(
        shpsData: shpsData,
        privateKeyPem: privateKeyPem,
      )) {
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
  }
}
