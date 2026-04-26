import 'dart:async';
import 'dart:typed_data';

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
    throw UnsupportedError('encryptFile is not supported on web');
  }

  static Future<Uint8List> decryptData({
    required Uint8List shpsData,
    required String privateKeyPem,
  }) async {
    throw UnsupportedError('decryptData is not supported on web');
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
    throw UnsupportedError('encryptFileStream is not supported on web');
  }

  static Stream<Uint8List> decryptDataStream({
    required Uint8List shpsData,
    required String privateKeyPem,
  }) {
    throw UnsupportedError('decryptDataStream is not supported on web');
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
    throw UnsupportedError('encryptFileToFile is not supported on web');
  }

  static Future<void> decryptDataToFile({
    required Uint8List shpsData,
    required String outputPath,
    required String privateKeyPem,
  }) async {
    throw UnsupportedError('decryptDataToFile is not supported on web');
  }
}
