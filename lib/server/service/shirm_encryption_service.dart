import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/signers/rsa_signer.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:basic_utils/basic_utils.dart';
import 'shirmps_header.dart';

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
    final originalBytes = await file.readAsBytes();

    try {
      Uint8List dataToEncrypt = originalBytes;
      if (compress) {
        final gzipEncoder = GZipEncoder();
        dataToEncrypt = Uint8List.fromList(gzipEncoder.encode(originalBytes));
      }

      final secureRandom = _getSecureRandom();
      final aesKey = secureRandom.nextBytes(32);
      final iv = secureRandom.nextBytes(12);

      final encryptedData = _aesGcmEncrypt(dataToEncrypt, aesKey, iv);
      final encryptedKey = _rsaOaepEncrypt(aesKey, publicKey);

      final header = ShirmpsHeader(creationDate: DateTime.now())
        ..originalFileName = originalFileName ?? file.path.split('/').last
        ..originalFileSize = originalBytes.length
        ..encryptedKey = base64.encode(encryptedKey)
        ..iv = base64.encode(iv)
        ..metadata = {}
        ..keyOwner = keyOwner
        ..userId = userId;

      if (compress) {
        header.metadata!['compressed'] = 'true';
      }

      if (privateKey != null) {
        final signatureBytes = _createSignature(originalBytes, privateKey);
        header.signature = base64.encode(signatureBytes);
      }

      final headerBytes = header.toJsonBytes();
      final headerLength = headerBytes.length;

      final result = Uint8List(4 + headerBytes.length + encryptedData.length);
      final byteData = ByteData.view(result.buffer);
      byteData.setInt32(0, headerLength, Endian.big);
      result.setAll(4, headerBytes);
      result.setAll(4 + headerBytes.length, encryptedData);

      return result;
    } catch (e) {
      rethrow;
    }
  }

  static Uint8List _createSignature(Uint8List data, RSAPrivateKey privateKey) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final signature = signer.generateSignature(data);
    return signature.bytes;
  }

  static Uint8List _aesGcmEncrypt(
    Uint8List plaintext,
    Uint8List key,
    Uint8List iv,
  ) {
    try {
      final keyParam = KeyParameter(key);
      final gcm = GCMBlockCipher(AESEngine())
        ..init(true, AEADParameters(keyParam, 128, iv, Uint8List(0)));

      final ciphertext = Uint8List(gcm.getOutputSize(plaintext.length));
      final processed = gcm.processBytes(
        plaintext,
        0,
        plaintext.length,
        ciphertext,
        0,
      );
      final finalised = gcm.doFinal(ciphertext, processed);
      final actualLength = processed + finalised;

      if (actualLength < ciphertext.length) {
        return Uint8List.sublistView(ciphertext, 0, actualLength);
      }
      return ciphertext;
    } catch (e) {
      rethrow;
    }
  }

  static Uint8List _rsaOaepEncrypt(Uint8List data, RSAPublicKey publicKey) {
    try {
      final cipher = OAEPEncoding.withSHA256(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
      return cipher.process(data);
    } catch (e) {
      rethrow;
    }
  }

  static SecureRandom _getSecureRandom() {
    final secureRandom = SecureRandom('Fortuna')
      ..seed(
        KeyParameter(
          Uint8List.fromList(
            List.generate(32, (_) => Random.secure().nextInt(256)),
          ),
        ),
      );
    return secureRandom;
  }
}
