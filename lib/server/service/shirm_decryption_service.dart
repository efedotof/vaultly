import 'dart:convert';
import 'dart:typed_data';
import 'package:basic_utils/basic_utils.dart';

import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'shirmps_header.dart';

class ShirmDecryptionService {
  static Future<Uint8List> decryptShps(
    Uint8List shpsBytes, {
    required String privateKeyPem,
  }) async {
    try {
      final privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);

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
        throw Exception('Missing encryptedKey or iv in header');
      }

      Uint8List encryptedAesKey;
      try {
        encryptedAesKey = base64.decode(header.encryptedKey!);
      } catch (e) {
        rethrow;
      }

      Uint8List iv;
      try {
        iv = base64.decode(header.iv!);
      } catch (e) {
        rethrow;
      }

      Uint8List? aesKeyBytes;
      final errors = <String>[];

      try {
        aesKeyBytes = _rsaOaepDecryptSHA256(encryptedAesKey, privateKey);
      } catch (e) {
        errors.add('SHA-256: $e');
      }

      if (aesKeyBytes == null) {
        try {
          aesKeyBytes = _rsaOaepDecryptSHA1(encryptedAesKey, privateKey);
        } catch (e) {
          errors.add('SHA-1: $e');
        }
      }

      if (aesKeyBytes == null) {
        throw Exception('Failed to decrypt AES key: ${errors.join(", ")}');
      }

      final encryptedData = shpsBytes.sublist(4 + headerLength);

      final decryptedData = _aesGcmDecrypt(encryptedData, aesKeyBytes, iv);

      return decryptedData;
    } catch (e) {
      rethrow;
    }
  }

  static Uint8List _rsaOaepDecryptSHA256(
    Uint8List encrypted,
    RSAPrivateKey privateKey,
  ) {
    final cipher = OAEPEncoding.withSHA256(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return cipher.process(encrypted);
  }

  static Uint8List _rsaOaepDecryptSHA1(
    Uint8List encrypted,
    RSAPrivateKey privateKey,
  ) {
    final cipher = OAEPEncoding.withSHA1(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return cipher.process(encrypted);
  }

  static Uint8List _aesGcmDecrypt(
    Uint8List ciphertext,
    Uint8List key,
    Uint8List iv,
  ) {
    try {
      final keyParam = KeyParameter(key);
      final gcm = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(keyParam, 128, iv, Uint8List(0)));

      final plaintext = Uint8List(gcm.getOutputSize(ciphertext.length));
      final len = gcm.processBytes(
        ciphertext,
        0,
        ciphertext.length,
        plaintext,
        0,
      );
      gcm.doFinal(plaintext, len);
      return plaintext;
    } catch (e) {
      rethrow;
    }
  }
}
