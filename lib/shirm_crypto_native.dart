import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'shirm_crypto_bindings_generated.dart';
import 'src/shirm_crypto_worker.dart' as worker;
import 'src/shirm_crypto_worker_pool.dart';

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

class ShirmCryptoImpl {
  static Future<Uint8List> encryptFile({
    required String inputPath,
    required String publicKeyPem,
    String? privateKeyPem,
    required String userId,
    required String keyOwner,
    String? originalFileName,
    bool compress = false,
  }) async {
    return CryptoWorkerPool.instance.encryptFile(
      inputPath: inputPath,
      publicKeyPem: publicKeyPem,
      privateKeyPem: privateKeyPem,
      userId: userId,
      keyOwner: keyOwner,
      originalFileName: originalFileName,
      compress: compress,
    );
  }

  static Future<Uint8List> decryptData({
    required Uint8List shpsData,
    required String privateKeyPem,
  }) async {
    return CryptoWorkerPool.instance.decryptData(
      shpsData: shpsData,
      privateKeyPem: privateKeyPem,
    );
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
    SendPort? isolateControlPort;
    var cancelled = false;

    final request = worker.EncryptStreamRequest(
      inputPath: inputPath,
      publicKeyPem: publicKeyPem,
      privateKeyPem: privateKeyPem,
      userId: userId,
      keyOwner: keyOwner,
      originalFileName: originalFileName,
      compress: compress,
    );

    controller.onCancel = () {
      cancelled = true;
      isolateControlPort?.send('cancel');
    };

    Isolate.spawn(worker.encryptStreamIsolate, [request, receivePort.sendPort]);

    receivePort.listen((message) {
      if (message is Map && message.containsKey('controlPort')) {
        isolateControlPort = message['controlPort'] as SendPort;
      } else if (message == null) {
        if (!cancelled) {
          controller.close();
        }
        receivePort.close();
      } else if (message is Uint8List) {
        if (!cancelled) controller.add(message);
      } else if (message is Map && message.containsKey('error')) {
        if (!cancelled) {
          controller.addError(Exception(message['error']));
          controller.close();
        }
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
    SendPort? isolateControlPort;
    var cancelled = false;

    final request = worker.DecryptStreamRequest(
      shpsData: shpsData,
      privateKeyPem: privateKeyPem,
    );

    controller.onCancel = () {
      cancelled = true;
      isolateControlPort?.send('cancel');
    };

    Isolate.spawn(worker.decryptStreamIsolate, [request, receivePort.sendPort]);

    receivePort.listen((message) {
      if (message is Map && message.containsKey('controlPort')) {
        isolateControlPort = message['controlPort'] as SendPort;
      } else if (message == null) {
        if (!cancelled) {
          controller.close();
        }
        receivePort.close();
      } else if (message is Uint8List) {
        if (!cancelled) controller.add(message);
      } else if (message is Map && message.containsKey('error')) {
        if (!cancelled) {
          controller.addError(Exception(message['error']));
          controller.close();
        }
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
