import 'dart:async';
import 'dart:typed_data';

import 'shirm_crypto_native.dart'
    if (dart.library.html) 'shirm_crypto_web.dart'
    as impl;

class ShirmCrypto {
  static Future<Uint8List> encryptFile({
    required String inputPath,
    required String publicKeyPem,
    String? privateKeyPem,
    required String userId,
    required String keyOwner,
    String? originalFileName,
    bool compress = false,
  }) {
    return impl.ShirmCryptoImpl.encryptFile(
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
  }) {
    return impl.ShirmCryptoImpl.decryptData(
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
    return impl.ShirmCryptoImpl.encryptFileStream(
      inputPath: inputPath,
      publicKeyPem: publicKeyPem,
      privateKeyPem: privateKeyPem,
      userId: userId,
      keyOwner: keyOwner,
      originalFileName: originalFileName,
      compress: compress,
    );
  }

  static Stream<Uint8List> decryptDataStream({
    required Uint8List shpsData,
    required String privateKeyPem,
  }) {
    return impl.ShirmCryptoImpl.decryptDataStream(
      shpsData: shpsData,
      privateKeyPem: privateKeyPem,
    );
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
  }) {
    return impl.ShirmCryptoImpl.encryptFileToFile(
      inputPath: inputPath,
      outputPath: outputPath,
      publicKeyPem: publicKeyPem,
      privateKeyPem: privateKeyPem,
      userId: userId,
      keyOwner: keyOwner,
      originalFileName: originalFileName,
      compress: compress,
    );
  }

  static Future<void> decryptDataToFile({
    required Uint8List shpsData,
    required String outputPath,
    required String privateKeyPem,
  }) {
    return impl.ShirmCryptoImpl.decryptDataToFile(
      shpsData: shpsData,
      outputPath: outputPath,
      privateKeyPem: privateKeyPem,
    );
  }
}
