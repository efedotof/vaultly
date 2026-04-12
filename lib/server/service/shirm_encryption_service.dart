import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/signers/rsa_signer.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:basic_utils/basic_utils.dart';
import 'shirmps_header.dart';

class ShirmEncryptionService {
  static void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('[ShirmEncryptionService] $message');
    }
  }

  static void _logError(String message) {
    if (kDebugMode) {
      debugPrint('[ShirmEncryptionService] ERROR: $message');
    }
  }

  static Future<Uint8List> encryptFile(
    File file, {
    required RSAPublicKey publicKey,
    required String userId,
    required String keyOwner,
    RSAPrivateKey? privateKey,
  }) async {
    _logDebug('encryptFile started for: ${file.path}');
    final originalBytes = await file.readAsBytes();
    _logDebug('Original file size: ${originalBytes.length} bytes');

    try {
      final secureRandom = _getSecureRandom();
      final aesKey = secureRandom.nextBytes(32);
      final iv = secureRandom.nextBytes(12);
      _logDebug('AES key and IV generated');

      final encryptedData = _aesGcmEncrypt(originalBytes, aesKey, iv);
      _logDebug(
        'AES-GCM encryption completed, encrypted size: ${encryptedData.length} bytes',
      );

      final encryptedKey = _rsaOaepEncrypt(aesKey, publicKey);
      _logDebug('AES key encrypted with RSA-OAEP');

      final header = ShirmpsHeader(creationDate: DateTime.now())
        ..originalFileName = file.path.split('/').last
        ..originalFileSize = originalBytes.length
        ..encryptedKey = base64.encode(encryptedKey)
        ..iv = base64.encode(iv)
        ..metadata = {}
        ..keyOwner = keyOwner
        ..userId = userId;

      if (privateKey != null) {
        final signatureBytes = _createSignature(originalBytes, privateKey);
        header.signature = base64.encode(signatureBytes);
        _logDebug(
          'Digital signature created, size: ${signatureBytes.length} bytes',
        );
      } else {
        _logDebug('No private key provided, skipping signature');
      }

      final headerBytes = header.toJsonBytes();
      final headerLength = headerBytes.length;
      _logDebug('Header size: $headerLength bytes');

      final result = Uint8List(4 + headerBytes.length + encryptedData.length);
      final byteData = ByteData.view(result.buffer);
      byteData.setInt32(0, headerLength, Endian.big);
      result.setAll(4, headerBytes);
      result.setAll(4 + headerBytes.length, encryptedData);

      _logDebug(
        'encryptFile completed, total output size: ${result.length} bytes',
      );
      return result;
    } catch (e, stack) {
      _logError('ERROR during encryption: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stack');
      }
      rethrow;
    }
  }

  static Uint8List _createSignature(Uint8List data, RSAPrivateKey privateKey) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final signature = signer.generateSignature(data);
    if (kDebugMode) {
      debugPrint("[_createSignature] Signature: $signature");
    }
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
      _logError('ERROR in AES-GCM encryption: $e');
      rethrow;
    }
  }

  static Uint8List _rsaOaepEncrypt(Uint8List data, RSAPublicKey publicKey) {
    try {
      final cipher = OAEPEncoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
      return cipher.process(data);
    } catch (e) {
      _logError('ERROR in RSA-OAEP encryption: $e');
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
