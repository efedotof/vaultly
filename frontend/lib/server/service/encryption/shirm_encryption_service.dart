import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:basic_utils/basic_utils.dart';
import 'package:shirm_crypto/shirm_crypto.dart';

class ShirmEncryptionService {
  static Future<Uint8List> encryptFile(
    File file, {
    required RSAPublicKey publicKey,
    required String userId,
    required String keyOwner,
    RSAPrivateKey? privateKey,
    String? originalFileName,
    bool compress = false,
  }) async {
    final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(publicKey);
    final privateKeyPem = privateKey != null
        ? CryptoUtils.encodeRSAPrivateKeyToPem(privateKey)
        : null;

    final result = ShirmCrypto.encryptFile(
      inputPath: file.path,
      publicKeyPem: publicKeyPem,
      privateKeyPem: privateKeyPem,
      userId: userId,
      keyOwner: keyOwner,
      originalFileName: originalFileName ?? file.path.split('/').last,
      compress: compress,
    );
    return result;
  }

  static Future<void> encryptFileToFile(
    File inputFile,
    File outputFile, {
    required RSAPublicKey publicKey,
    required String userId,
    required String keyOwner,
    RSAPrivateKey? privateKey,
    String? originalFileName,
    bool compress = false,
  }) async {
    final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(publicKey);
    final privateKeyPem = privateKey != null
        ? CryptoUtils.encodeRSAPrivateKeyToPem(privateKey)
        : null;

    await ShirmCrypto.encryptFileToFile(
      inputPath: inputFile.path,
      outputPath: outputFile.path,
      publicKeyPem: publicKeyPem,
      privateKeyPem: privateKeyPem,
      userId: userId,
      keyOwner: keyOwner,
      originalFileName: originalFileName ?? inputFile.path.split('/').last,
      compress: compress,
    );
  }

  static Future<void> encryptFileToSink(
    File inputFile, {
    required StreamSink<List<int>> sink,
    required RSAPublicKey publicKey,
    required String userId,
    required String keyOwner,
    RSAPrivateKey? privateKey,
    String? originalFileName,
    bool compress = false,
  }) async {
    final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(publicKey);
    final privateKeyPem = privateKey != null
        ? CryptoUtils.encodeRSAPrivateKeyToPem(privateKey)
        : null;

    final stream = ShirmCrypto.encryptFileStream(
      inputPath: inputFile.path,
      publicKeyPem: publicKeyPem,
      privateKeyPem: privateKeyPem,
      userId: userId,
      keyOwner: keyOwner,
      originalFileName: originalFileName ?? inputFile.path.split('/').last,
      compress: compress,
    );

    await for (final chunk in stream) {
      sink.add(chunk);
    }
    await sink.close();
  }

  static Future<Uint8List> encryptBytes(
    Uint8List originalBytes, {
    required String publicKeyPem,
    required String userId,
    required String keyOwner,
    String? privateKeyPem,
    String? originalFileName,
    bool compress = false,
  }) async {
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempInputPath = '${tempDir.path}/shirm_input_$timestamp.bin';
    final tempInputFile = File(tempInputPath);
    try {
      await tempInputFile.writeAsBytes(originalBytes);

      final bytesBuilder = BytesBuilder(copy: false);
      final stream = ShirmCrypto.encryptFileStream(
        inputPath: tempInputPath,
        publicKeyPem: publicKeyPem,
        privateKeyPem: privateKeyPem,
        userId: userId,
        keyOwner: keyOwner,
        originalFileName: originalFileName ?? 'file.bin',
        compress: compress,
      );

      await for (final chunk in stream) {
        bytesBuilder.add(chunk);
      }
      final result = bytesBuilder.takeBytes();
      return result;
    } finally {
      try {
        if (await tempInputFile.exists()) {
          await tempInputFile.delete();
        }
      } catch (_) {}
    }
  }
}
