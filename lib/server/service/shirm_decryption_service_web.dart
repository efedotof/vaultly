import 'dart:convert';
import 'dart:typed_data';
import 'package:webcrypto/webcrypto.dart' as web;
import 'package:archive/archive.dart';
import 'shirmps_header.dart';

class ShirmDecryptionService {
  static Future<Uint8List> decryptShps(
    Uint8List shpsBytes, {
    required String privateKeyPem,
  }) async {
    try {
      final byteData = shpsBytes.buffer.asByteData(
        shpsBytes.offsetInBytes,
        shpsBytes.length,
      );
      final headerLength = byteData.getInt32(0, Endian.big);

      if (headerLength <= 0 || headerLength > 20 * 1024) {
        throw Exception('Invalid header length: $headerLength');
      }

      final headerBytes = shpsBytes.sublist(4, 4 + headerLength);
      final header = ShirmpsHeader.fromJsonBytes(headerBytes);

      if (header.encryptedKey == null || header.iv == null) {
        throw Exception('Missing encryptedKey or iv');
      }

      final encryptedAesKey = base64.decode(header.encryptedKey!);
      final iv = base64.decode(header.iv!);

      Uint8List? aesKeyBytes;
      final errors = <Exception>[];

      for (final hash in [web.Hash.sha256, web.Hash.sha1]) {
        try {
          final privateKey = await _importRsaOaepPrivateKey(
            privateKeyPem,
            hash,
          );
          aesKeyBytes = await privateKey.decryptBytes(encryptedAesKey);

          break;
        } catch (e) {
          errors.add(Exception('Failed with hash $hash: $e'));
        }
      }

      if (aesKeyBytes == null) {
        throw Exception(
          'Failed to decrypt AES key with any hash. Errors: $errors',
        );
      }

      final encryptedData = shpsBytes.sublist(4 + headerLength);
      final aesKey = await web.AesGcmSecretKey.importRawKey(aesKeyBytes);
      final decryptedData = await aesKey.decryptBytes(encryptedData, iv);

      if (header.compressed) {
        try {
          final gzipDecoder = GZipDecoder();
          final decompressed = gzipDecoder.decodeBytes(decryptedData);

          return Uint8List.fromList(decompressed);
        } catch (e) {
          throw Exception('Failed to decompress gzip data: $e');
        }
      }

      return decryptedData;
    } catch (e) {
      rethrow;
    }
  }

  static Future<web.RsaOaepPrivateKey> _importRsaOaepPrivateKey(
    String pem,
    web.Hash hash,
  ) async {
    final b64 = pem
        .replaceFirst('-----BEGIN PRIVATE KEY-----', '')
        .replaceFirst('-----END PRIVATE KEY-----', '')
        .replaceFirst('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceFirst('-----END RSA PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s'), '');
    final keyData = base64Decode(b64);
    return await web.RsaOaepPrivateKey.importPkcs8Key(keyData, hash);
  }
}
