import 'dart:convert';
import 'dart:math';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:pinenacl/ed25519.dart' as nacl;
import 'package:vaulth_app/server/service/logger_service.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter/foundation.dart';

class SeedPhraseService {
  static String generateMnemonic() {
    final mnemonic = bip39.generateMnemonic(strength: 256);
    return mnemonic;
  }

  static bool validateMnemonic(String mnemonic) {
    final isValid = bip39.validateMnemonic(mnemonic);
    return isValid;
  }

  static Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''}) {
    final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);

    return seed;
  }

  static Future<({String publicKeyBase64, String privateKeyBase64})>
  deriveEd25519KeyPair(
    Uint8List seed, {
    String derivationPath = "m/44'/0'/0'/0'/0'",
  }) async {
    try {
      LoggerService().debug('[SeedPhrase] seed length: ${seed.length} bytes');

      final keyData = await ED25519_HD_KEY.derivePath(derivationPath, seed);

      final privateKey = keyData.key is Uint8List
          ? keyData.key as Uint8List
          : Uint8List.fromList(keyData.key);
      final chainCode = keyData.chainCode is Uint8List
          ? keyData.chainCode as Uint8List
          : Uint8List.fromList(keyData.chainCode);

      LoggerService().debug(
        '[SeedPhrase] privateKey length: ${privateKey.length}',
      );
      LoggerService().debug(
        '[SeedPhrase] chainCode length: ${chainCode.length}',
      );

      final privateKeyFull = Uint8List(64)
        ..setAll(0, privateKey)
        ..setAll(32, chainCode);

      final signingKey = nacl.SigningKey.fromSeed(privateKey);
      final publicKey = signingKey.publicKey;

      return (
        publicKeyBase64: base64Encode(publicKey),
        privateKeyBase64: base64Encode(privateKeyFull),
      );
    } catch (e, stack) {
      LoggerService().error('[SeedPhrase] Error', error: e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<String> encryptRsaKeyWithMnemonic(
    String rsaPrivateKeyPem,
    String mnemonic,
  ) async {
    final salt = _CryptoHelper.generateSalt();

    final keyBytes = await _deriveKeyFromMnemonic(mnemonic, salt);

    final encrypted = await _CryptoHelper.encryptWithBytes(
      rsaPrivateKeyPem,
      keyBytes,
    );

    return jsonEncode({'salt': salt, 'ciphertext': encrypted});
  }

  static Future<String> decryptRsaKeyWithMnemonic(
    String encryptedPackage,
    String mnemonic,
  ) async {
    final json = jsonDecode(encryptedPackage);
    final salt = json['salt'];
    final ciphertext = json['ciphertext'];

    final keyBytes = await _deriveKeyFromMnemonic(mnemonic, salt);

    final decrypted = await _CryptoHelper.decryptWithBytes(
      ciphertext,
      keyBytes,
    );

    return decrypted;
  }

  static Future<Uint8List> _deriveKeyFromMnemonic(
    String mnemonic,
    String salt,
  ) async {
    final pbkdf2 = crypto.Pbkdf2(
      macAlgorithm: crypto.Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: crypto.SecretKey(utf8.encode(mnemonic)),
      nonce: base64Decode(salt),
    );
    final bytes = await secretKey.extractBytes();

    return Uint8List.fromList(bytes);
  }
}

class _CryptoHelper {
  static final _aes = crypto.AesGcm.with256bits();

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt = base64Encode(bytes);

    return salt;
  }

  static Future<String> encryptWithBytes(
    String text,
    Uint8List keyBytes,
  ) async {
    final secretKey = crypto.SecretKey(keyBytes);
    final nonce = List<int>.generate(12, (_) => Random.secure().nextInt(256));

    final box = await _aes.encrypt(
      utf8.encode(text),
      secretKey: secretKey,
      nonce: nonce,
    );
    final result = jsonEncode({
      'cipherText': base64Encode(box.cipherText),
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
    });

    return result;
  }

  static Future<String> decryptWithBytes(
    String data,
    Uint8List keyBytes,
  ) async {
    final secretKey = crypto.SecretKey(keyBytes);
    final json = jsonDecode(data);
    final box = crypto.SecretBox(
      base64Decode(json['cipherText']),
      nonce: base64Decode(json['nonce']),
      mac: crypto.Mac(base64Decode(json['mac'])),
    );

    final decrypted = await _aes.decrypt(box, secretKey: secretKey);
    final text = utf8.decode(decrypted);

    return text;
  }
}
