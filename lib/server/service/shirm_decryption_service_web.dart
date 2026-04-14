import 'dart:convert';
import 'dart:typed_data';
import 'dart:js' as js;

import 'shirmps_header.dart';

class ShirmDecryptionServiceWeb {
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

      final privateKey = await _importPrivateKeyJs(privateKeyPem);

      final aesKeyBytes = await _rsaOaepDecryptJs(encryptedAesKey, privateKey);

      final encryptedData = shpsBytes.sublist(4 + headerLength);

      final decryptedData = await _aesGcmDecryptJs(
        encryptedData,
        aesKeyBytes,
        iv,
      );

      return decryptedData;
    } catch (e) {
      rethrow;
    }
  }

  static Future<dynamic> _importPrivateKeyJs(String pem) async {
    final b64 = pem
        .replaceFirst('-----BEGIN PRIVATE KEY-----', '')
        .replaceFirst('-----END PRIVATE KEY-----', '')
        .replaceFirst('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceFirst('-----END RSA PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s'), '');
    final keyData = base64Decode(b64);
    final jsKeyData = js.JsObject.jsify(keyData);

    final subtle = js.context['crypto']['subtle'];
    return await subtle.callMethod('importKey', [
      'pkcs8',
      jsKeyData,
      {'name': 'RSA-OAEP', 'hash': 'SHA-256'},
      false,
      ['decrypt'],
    ]);
  }

  static Future<Uint8List> _rsaOaepDecryptJs(
    Uint8List encrypted,
    dynamic privateKey,
  ) async {
    final encryptedJs = js.JsObject.jsify(encrypted);
    final subtle = js.context['crypto']['subtle'];
    final decryptedJs = await subtle.callMethod('decrypt', [
      {'name': 'RSA-OAEP'},
      privateKey,
      encryptedJs,
    ]);
    return Uint8List.fromList(List<int>.from(decryptedJs as List));
  }

  static Future<Uint8List> _aesGcmDecryptJs(
    Uint8List ciphertext,
    Uint8List key,
    Uint8List iv,
  ) async {
    final subtle = js.context['crypto']['subtle'];
    final keyJs = await subtle.callMethod('importKey', [
      'raw',
      js.JsObject.jsify(key),
      'AES-GCM',
      false,
      ['decrypt'],
    ]);
    final decryptedJs = await subtle.callMethod('decrypt', [
      {'name': 'AES-GCM', 'iv': js.JsObject.jsify(iv)},
      keyJs,
      js.JsObject.jsify(ciphertext),
    ]);
    return Uint8List.fromList(List<int>.from(decryptedJs as List));
  }
}
