import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webcrypto/webcrypto.dart' as web;
import 'package:vaulth_app/server/service/system/logger_service.dart';
import 'rsa_key_generator_web.dart';

class KeyManagerServiceWeb {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _CryptoHelperWeb _crypto = _CryptoHelperWeb();

  static const _userPublicKey = 'user_public_key';
  static const _userPrivateKey = 'user_private_key';
  static const _userSalt = 'user_salt';

  static const _devicePublicKey = 'device_public_key';
  static const _devicePrivateKey = 'device_private_key';
  static const _deviceSalt = 'device_salt';

  String? _cachedPrivateKeyPem;

  Future<String?> getUserSalt() => _storage.read(key: _userSalt);

  Future<String> generateAndStoreUserKeyPair(String password) async {
    LoggerService().debug('[KeyManagerServiceWeb] Generating user key pair...');
    try {
      final pair = await RsaKeyGeneratorWeb.generate();
      final publicPem = pair.publicKeyPem;
      final privatePem = pair.privateKeyPem;
      LoggerService().debug('[KeyManagerServiceWeb] RSA key pair generated');

      final salt = _crypto.generateSalt();
      final key = await _crypto.deriveKey(password, salt);
      final encrypted = await _crypto.encrypt(privatePem, key);
      LoggerService().debug(
        '[KeyManagerServiceWeb] Private key encrypted with password',
      );

      await _storage.write(key: _userPublicKey, value: publicPem);
      await _storage.write(key: _userPrivateKey, value: encrypted);
      await _storage.write(key: _userSalt, value: salt);
      _cachedPrivateKeyPem = privatePem;
      LoggerService().debug(
        '[KeyManagerServiceWeb] User keys stored successfully',
      );
      return publicPem;
    } catch (e) {
      LoggerService().error(
        '[KeyManagerServiceWeb] ERROR generating user keys: $e',
      );
      rethrow;
    }
  }

  Future<String?> getPublicKey() async => getUserPublicKey();

  Future<String?> decryptPrivateKeyWithPassword(
    String encryptedKey,
    String salt,
    String password,
  ) async {
    try {
      final key = await _crypto.deriveKey(password, salt);
      return await _crypto.decrypt(encryptedKey, key);
    } catch (e) {
      LoggerService().error(
        '[KeyManagerServiceWeb] ERROR decrypting private key with password: $e',
      );
      return null;
    }
  }

  Future<String?> getUserPublicKey() async {
    final pub = await _storage.read(key: _userPublicKey);
    LoggerService().debug(
      '[KeyManagerServiceWeb] getUserPublicKey: ${pub != null ? 'found' : 'not found'}',
    );
    return pub;
  }

  Future<String?> getUserEncryptedPrivateKeyData() async {
    return await _storage.read(key: _userPrivateKey);
  }

  Future<void> storeUserPrivateKeyEncryptedWithPassword(
    String privateKeyPem,
    String password, {
    String? salt,
  }) async {
    final effectiveSalt = salt ?? _crypto.generateSalt();
    final derivedKey = await _crypto.deriveKey(password, effectiveSalt);
    final encrypted = await _crypto.encrypt(privateKeyPem, derivedKey);
    await _storage.write(key: _userPrivateKey, value: encrypted);
    await _storage.write(key: _userSalt, value: effectiveSalt);
    _cachedPrivateKeyPem = privateKeyPem;
    LoggerService().debug(
      '[KeyManagerServiceWeb] User private key stored (encrypted with password)',
    );
  }

  Future<void> saveUserPublicKey(String publicKeyPem) async {
    await _storage.write(key: _userPublicKey, value: publicKeyPem);
    LoggerService().debug('[KeyManagerServiceWeb] User public key saved');
  }

  Future<String?> getPrivateKeyPEM(String password) async {
    if (_cachedPrivateKeyPem != null) {
      LoggerService().debug(
        '[KeyManagerServiceWeb] Returning cached private key PEM',
      );
      return _cachedPrivateKeyPem;
    }
    try {
      final encrypted = await _storage.read(key: _userPrivateKey);
      final salt = await _storage.read(key: _userSalt);
      if (encrypted == null || salt == null) {
        LoggerService().debug(
          '[KeyManagerServiceWeb] Private key or salt not found in storage',
        );
        return null;
      }
      final key = await _crypto.deriveKey(password, salt);
      final pem = await _crypto.decrypt(encrypted, key);
      if (pem != null) _cachedPrivateKeyPem = pem;
      LoggerService().debug(
        '[KeyManagerServiceWeb] Private key PEM ${pem != null ? 'decrypted' : 'decryption failed'}',
      );
      return pem;
    } catch (e) {
      LoggerService().error(
        '[KeyManagerServiceWeb] ERROR getting private key PEM: $e',
      );
      return null;
    }
  }

  Future<bool> hasDeviceKeys() async {
    final pub = await _storage.read(key: _devicePublicKey);
    final priv = await _storage.read(key: _devicePrivateKey);
    final exists = pub != null && priv != null;
    LoggerService().debug('[KeyManagerServiceWeb] hasDeviceKeys: $exists');
    return exists;
  }

  Future<String> generateAndStoreDeviceKeyPair(String password) async {
    LoggerService().debug(
      '[KeyManagerServiceWeb] Generating device key pair...',
    );
    try {
      final pair = await RsaKeyGeneratorWeb.generate();
      final publicPem = pair.publicKeyPem;
      final privatePem = pair.privateKeyPem;
      final salt = _crypto.generateSalt();
      final key = await _crypto.deriveKey(password, salt);
      final encrypted = await _crypto.encrypt(privatePem, key);
      await _storage.write(key: _devicePublicKey, value: publicPem);
      await _storage.write(key: _devicePrivateKey, value: encrypted);
      await _storage.write(key: _deviceSalt, value: salt);
      LoggerService().debug(
        '[KeyManagerServiceWeb] Device keys stored successfully',
      );
      return publicPem;
    } catch (e, stack) {
      LoggerService().error(
        '[KeyManagerServiceWeb] ERROR generating device keys',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<String?> getDevicePublicKey() async {
    final pub = await _storage.read(key: _devicePublicKey);
    LoggerService().debug(
      '[KeyManagerServiceWeb] getDevicePublicKey: ${pub != null ? 'found' : 'not found'}',
    );
    return pub;
  }

  Future<String?> getDevicePrivateKeyPEM(String password) async {
    try {
      final encrypted = await _storage.read(key: _devicePrivateKey);
      final salt = await _storage.read(key: _deviceSalt);
      if (encrypted == null || salt == null) {
        LoggerService().debug(
          '[KeyManagerServiceWeb] Device private key PEM not found',
        );
        return null;
      }
      final key = await _crypto.deriveKey(password, salt);
      final pem = await _crypto.decrypt(encrypted, key);
      LoggerService().debug(
        '[KeyManagerServiceWeb] Device private key PEM ${pem != null ? 'decrypted' : 'decryption failed'}',
      );
      return pem;
    } catch (e) {
      LoggerService().error(
        '[KeyManagerServiceWeb] ERROR getting device private key PEM: $e',
      );
      return null;
    }
  }

  Future<String> hybridEncryptWithPublicKeyPem(
    String data,
    String publicKeyPem,
  ) async {
    final publicKey = await _importPublicKeyFromPem(publicKeyPem);
    final aesKey = _crypto.generateAesKey();
    final iv = _crypto.generateIv();
    final encryptedData = await _crypto.encryptAesGcm(
      utf8.encode(data),
      aesKey,
      iv,
    );
    final encryptedAesKey = await publicKey.encryptBytes(aesKey);

    final result = {
      'encryptedKey': base64Encode(encryptedAesKey),
      'iv': base64Encode(iv),
      'ciphertext': base64Encode(encryptedData),
    };
    return jsonEncode(result);
  }

  Future<String> hybridDecryptWithPrivateKeyPem(
    String encryptedPackage,
    String privateKeyPem,
  ) async {
    final json = jsonDecode(encryptedPackage);
    final encryptedAesKey = base64Decode(json['encryptedKey']);
    final iv = base64Decode(json['iv']);
    final ciphertext = base64Decode(json['ciphertext']);
    final privateKey = await _importPrivateKeyFromPem(privateKeyPem);
    final aesKey = await privateKey.decryptBytes(encryptedAesKey);
    final decrypted = await _crypto.decryptAesGcm(ciphertext, aesKey, iv);
    return utf8.decode(decrypted);
  }

  Future<web.RsaOaepPublicKey> _importPublicKeyFromPem(String pem) async {
    final b64 = pem
        .replaceFirst('-----BEGIN PUBLIC KEY-----', '')
        .replaceFirst('-----END PUBLIC KEY-----', '')
        .replaceAll(RegExp(r'\s'), '');
    final spki = base64Decode(b64);
    return await web.RsaOaepPublicKey.importSpkiKey(spki, web.Hash.sha256);
  }

  Future<web.RsaOaepPrivateKey> _importPrivateKeyFromPem(String pem) async {
    final b64 = pem
        .replaceFirst('-----BEGIN PRIVATE KEY-----', '')
        .replaceFirst('-----END PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s'), '');
    final pkcs8 = base64Decode(b64);
    return await web.RsaOaepPrivateKey.importPkcs8Key(pkcs8, web.Hash.sha256);
  }

  Future<void> clearUserKeys() async {
    LoggerService().debug('[KeyManagerServiceWeb] Clearing user keys only...');
    await _storage.delete(key: _userPublicKey);
    await _storage.delete(key: _userPrivateKey);
    await _storage.delete(key: _userSalt);
    _cachedPrivateKeyPem = null;
    LoggerService().debug(
      '[KeyManagerServiceWeb] User keys cleared (device keys preserved)',
    );
  }

  Future<void> clearAllKeys() async {
    LoggerService().debug('[KeyManagerServiceWeb] Clearing all keys...');
    await _storage.delete(key: _userPublicKey);
    await _storage.delete(key: _userPrivateKey);
    await _storage.delete(key: _userSalt);
    await _storage.delete(key: _devicePublicKey);
    await _storage.delete(key: _devicePrivateKey);
    await _storage.delete(key: _deviceSalt);
    _cachedPrivateKeyPem = null;
    LoggerService().debug('[KeyManagerServiceWeb] All keys cleared');
  }

  Future<String> encryptWithPassword(String plaintext, String password) async {
    final salt = await getUserSalt() ?? _crypto.generateSalt();
    final key = await _crypto.deriveKey(password, salt);
    return await _crypto.encrypt(plaintext, key);
  }
}

class _CryptoHelperWeb {
  String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  Uint8List generateAesKey() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
  }

  Uint8List generateIv() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(12, (_) => random.nextInt(256)));
  }

  Future<Uint8List> encryptAesGcm(
    Uint8List plaintext,
    Uint8List key,
    Uint8List iv,
  ) async {
    final secretKey = await web.AesGcmSecretKey.importRawKey(key);
    return await secretKey.encryptBytes(plaintext, iv);
  }

  Future<Uint8List> decryptAesGcm(
    Uint8List ciphertextWithTag,
    Uint8List key,
    Uint8List iv,
  ) async {
    final secretKey = await web.AesGcmSecretKey.importRawKey(key);
    return await secretKey.decryptBytes(ciphertextWithTag, iv);
  }

  Future<Uint8List> deriveKey(String password, String salt) async {
    final key = await web.Pbkdf2SecretKey.importRawKey(utf8.encode(password));
    return await key.deriveBits(
      256,
      web.Hash.sha256,
      base64Decode(salt),
      100000,
    );
  }

  Future<String> encrypt(String text, Uint8List derivedKey) async {
    final nonce = List<int>.generate(12, (_) => Random.secure().nextInt(256));
    final aesKey = await web.AesGcmSecretKey.importRawKey(derivedKey);
    final encrypted = await aesKey.encryptBytes(utf8.encode(text), nonce);
    final ciphertext = encrypted.sublist(0, encrypted.length - 16);
    final tag = encrypted.sublist(encrypted.length - 16);
    final result = jsonEncode({
      'cipherText': base64Encode(ciphertext),
      'nonce': base64Encode(nonce),
      'mac': base64Encode(tag),
    });
    return result;
  }

  Future<String?> decrypt(String data, Uint8List derivedKey) async {
    try {
      final json = jsonDecode(data);
      final ciphertext = base64Decode(json['cipherText']);
      final nonce = base64Decode(json['nonce']);
      final tag = base64Decode(json['mac']);
      final combined = Uint8List(ciphertext.length + tag.length)
        ..setAll(0, ciphertext)
        ..setAll(ciphertext.length, tag);
      final aesKey = await web.AesGcmSecretKey.importRawKey(derivedKey);
      final decrypted = await aesKey.decryptBytes(combined, nonce);
      return utf8.decode(decrypted);
    } catch (e) {
      LoggerService().error('[_CryptoHelperWeb] ERROR during decryption: $e');
      return null;
    }
  }
}
