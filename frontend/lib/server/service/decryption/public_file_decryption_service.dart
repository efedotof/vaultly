import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webcrypto/webcrypto.dart' as web;

import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:basic_utils/basic_utils.dart';

class PublicFileDecryptionService {
  static Future<Uint8List> decryptPublicFile({
    required Uint8List shpsData,
    required String reEncryptedKeyBase64,
    required String ivBase64,
    required String clientPrivateKeyPem,
  }) async {
    final encryptedAesKey = base64Decode(reEncryptedKeyBase64);
    final iv = base64Decode(ivBase64);

    Uint8List aesKey;
    if (kIsWeb) {
      final privateKey = await _importPrivateKeyFromPem(clientPrivateKeyPem);
      aesKey = await privateKey.decryptBytes(encryptedAesKey);
    } else {
      final privateKey = CryptoUtils.rsaPrivateKeyFromPem(clientPrivateKeyPem);
      aesKey = _rsaOaepDecrypt(encryptedAesKey, privateKey);
    }

    final encryptedData = _extractEncryptedDataFromShps(shpsData);

    return kIsWeb
        ? await _aesGcmDecryptWeb(encryptedData, aesKey, iv)
        : _aesGcmDecryptNative(encryptedData, aesKey, iv);
  }

  static Uint8List _extractEncryptedDataFromShps(Uint8List shpsData) {
    if (shpsData.length < 4) {
      throw Exception('SHPS file too short');
    }
    final byteData = shpsData.buffer.asByteData(
      shpsData.offsetInBytes,
      shpsData.length,
    );
    final headerLength = byteData.getInt32(0, Endian.big);
    if (headerLength < 0 || headerLength > shpsData.length - 4) {
      throw Exception('Invalid SHPS header length: $headerLength');
    }
    return shpsData.sublist(4 + headerLength);
  }

  static Uint8List _rsaOaepDecrypt(
    Uint8List encrypted,
    RSAPrivateKey privateKey,
  ) {
    final oaep = OAEPEncoding.withSHA256(RSAEngine());
    oaep.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return oaep.process(encrypted);
  }

  static Uint8List _aesGcmDecryptNative(
    Uint8List ciphertext,
    Uint8List key,
    Uint8List iv,
  ) {
    final keyParam = KeyParameter(key);
    final gcm = GCMBlockCipher(AESEngine());
    const macSizeBits = 128;
    final params = AEADParameters(keyParam, macSizeBits, iv, Uint8List(0));
    gcm.init(false, params);

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
  }

  static Future<web.RsaOaepPrivateKey> _importPrivateKeyFromPem(
    String pem,
  ) async {
    final b64 = pem
        .replaceFirst('-----BEGIN PRIVATE KEY-----', '')
        .replaceFirst('-----END PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s'), '');
    return await web.RsaOaepPrivateKey.importPkcs8Key(
      base64Decode(b64),
      web.Hash.sha256,
    );
  }

  static Future<Uint8List> _aesGcmDecryptWeb(
    Uint8List ciphertext,
    Uint8List key,
    Uint8List iv,
  ) async {
    final secretKey = await web.AesGcmSecretKey.importRawKey(key);
    return await secretKey.decryptBytes(ciphertext, iv);
  }

  static Stream<Uint8List> decryptPublicFileStream({
    required Stream<Uint8List> encryptedStream,
    required String reEncryptedKeyBase64,
    required String ivBase64,
    required String clientPrivateKeyPem,
  }) async* {
    if (!kIsWeb) {
      throw UnsupportedError('Streaming decryption only supported on web');
    }

    final headerLenBuffer = await _readExactly(encryptedStream, 4);
    final headerLength = ByteData.view(
      headerLenBuffer.buffer,
    ).getInt32(0, Endian.big);
    await _readExactly(encryptedStream, headerLength);

    final encryptedAesKey = base64Decode(reEncryptedKeyBase64);
    final iv = base64Decode(ivBase64);

    final privateKey = await _importPrivateKeyFromPem(clientPrivateKeyPem);
    final aesKey = await privateKey.decryptBytes(encryptedAesKey);
    final aesSecretKey = await web.AesGcmSecretKey.importRawKey(aesKey);

    List<int> buffer = [];
    await for (final chunk in encryptedStream) {
      buffer.addAll(chunk);
    }
    final allEncrypted = Uint8List.fromList(buffer);
    final decrypted = await aesSecretKey.decryptBytes(allEncrypted, iv);
    yield decrypted;
  }

  static Future<Uint8List> _readExactly(
    Stream<Uint8List> stream,
    int length,
  ) async {
    final completer = Completer<Uint8List>();
    List<int> buffer = [];
    int received = 0;
    StreamSubscription<Uint8List>? subscription;
    subscription = stream.listen(
      (data) {
        buffer.addAll(data);
        received += data.length;
        if (received >= length) {
          subscription?.cancel();
          completer.complete(Uint8List.fromList(buffer.sublist(0, length)));
        }
      },
      onError: (err) {
        if (!completer.isCompleted) completer.completeError(err);
      },
      onDone: () {
        if (!completer.isCompleted && received < length) {
          completer.completeError(
            Exception('Stream ended before reading $length bytes'),
          );
        }
      },
    );
    return completer.future;
  }
}
