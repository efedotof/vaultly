import 'dart:convert';
import 'dart:typed_data';
import 'package:webcrypto/webcrypto.dart' as web;
import 'shirmps_header.dart';

class ShirmDecryptionServiceWeb {
  static Future<Uint8List> decryptShps(
    Uint8List shpsBytes, {
    required String privateKeyPem,
  }) async {
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
    final encryptedAesKey = base64.decode(header.encryptedKey!);
    final privateKey = await _importPrivateKeyFromPem(privateKeyPem);
    final aesKeyBytes = await privateKey.decryptBytes(encryptedAesKey);
    final iv = base64.decode(header.iv!);
    final encryptedData = shpsBytes.sublist(4 + headerLength);

    final decryptedData = await _aesGcmDecrypt(encryptedData, aesKeyBytes, iv);

    return decryptedData;
  }

  static Future<web.RsaOaepPrivateKey> _importPrivateKeyFromPem(
    String pem,
  ) async {
    final b64 = pem
        .replaceFirst('-----BEGIN PRIVATE KEY-----', '')
        .replaceFirst('-----END PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s'), '');
    final pkcs8 = base64Decode(b64);
    return await web.RsaOaepPrivateKey.importPkcs8Key(pkcs8, web.Hash.sha256);
  }

  static Future<Uint8List> _aesGcmDecrypt(
    Uint8List ciphertext,
    Uint8List key,
    Uint8List iv,
  ) async {
    final secretKey = await web.AesGcmSecretKey.importRawKey(key);
    return await secretKey.decryptBytes(ciphertext, iv);
  }
}
