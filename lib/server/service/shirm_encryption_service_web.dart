import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:webcrypto/webcrypto.dart' as web;
import 'shirmps_header.dart';

class ShirmEncryptionServiceWeb {
  static Future<Uint8List> encryptBytes(
    Uint8List originalBytes, {
    required String publicKeyPem,
    required String userId,
    required String keyOwner,
    String? privateKeyPem,
    String? originalFileName,
  }) async {
    final aesKey = _generateRandomBytes(32);
    final iv = _generateRandomBytes(12);
    final encryptedData = await _aesGcmEncrypt(originalBytes, aesKey, iv);
    final publicKey = await _importPublicKeyFromPem(publicKeyPem);
    final encryptedKey = await publicKey.encryptBytes(aesKey);
    final header = ShirmpsHeader(creationDate: DateTime.now())
      ..originalFileName = originalFileName ?? 'file.bin'
      ..originalFileSize = originalBytes.length
      ..encryptedKey = base64.encode(encryptedKey)
      ..iv = base64.encode(iv)
      ..metadata = {}
      ..keyOwner = keyOwner
      ..userId = userId;

    if (privateKeyPem != null) {}

    final headerBytes = header.toJsonBytes();
    final headerLength = headerBytes.length;
    final result = Uint8List(4 + headerBytes.length + encryptedData.length);
    final byteData = ByteData.view(result.buffer);
    byteData.setInt32(0, headerLength, Endian.big);
    result.setAll(4, headerBytes);
    result.setAll(4 + headerBytes.length, encryptedData);

    return result;
  }

  static Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Future<web.RsaOaepPublicKey> _importPublicKeyFromPem(
    String pem,
  ) async {
    final b64 = _pemToBase64(pem);
    final spki = base64Decode(b64);
    return await web.RsaOaepPublicKey.importSpkiKey(spki, web.Hash.sha256);
  }

  static String _pemToBase64(String pem) {
    return pem
        .replaceFirst(RegExp(r'-----BEGIN [A-Z ]+-----'), '')
        .replaceFirst(RegExp(r'-----END [A-Z ]+-----'), '')
        .replaceAll(RegExp(r'\s'), '');
  }

  static Future<Uint8List> _aesGcmEncrypt(
    Uint8List plaintext,
    Uint8List key,
    Uint8List iv,
  ) async {
    final secretKey = await web.AesGcmSecretKey.importRawKey(key);
    return await secretKey.encryptBytes(plaintext, iv);
  }
}
