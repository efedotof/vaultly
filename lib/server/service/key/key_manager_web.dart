import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';
import 'package:webcrypto/webcrypto.dart' as web;
import 'rsa_key_generator_web.dart';

class KeyManagerService extends GetxService {
  bool _isInit = false;

  Future<KeyManagerService> init() async {
    try {
      _isInit = true;
      Logger.d("Успешная инициализация", tag: 'KeyManagerService');
      return this;
    } catch (e) {
      Logger.d("Ошибка инициализации: $e", tag: 'KeyManagerService');
      return throw Exception(
        "[KeyManagerService] ошибка инициализации сервиса",
      );
    }
  }

  bool get isInitial => _isInit;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _CryptoHelperWeb _crypto = _CryptoHelperWeb();

  static const String pendingUserId = '__pending__';

  static String _pubKey(String userId) => 'user_public_key:$userId';
  static String _privKey(String userId) => 'user_private_key:$userId';
  static String _saltKey(String userId) => 'user_salt:$userId';

  static const _devicePublicKey = 'device_public_key';
  static const _devicePrivateKey = 'device_private_key';
  static const _deviceSalt = 'device_salt';

  String? _cachedPrivateKeyPem;
  String? _cachedPrivateKeyUserId;

  void _invalidateCache() {
    _cachedPrivateKeyPem = null;
    _cachedPrivateKeyUserId = null;
  }

  Future<String?> getUserSalt({required String userId}) =>
      _storage.read(key: _saltKey(userId));

  Future<void> generateAndStoreUserKeyPair({
    required String userId,
    required String password,
  }) async {
    Logger.d('[KeyManagerServiceWeb] Generating user key pair for $userId...');
    try {
      final pair = await RsaKeyGeneratorWeb.generate();
      final publicPem = pair.publicKeyPem;
      final privatePem = pair.privateKeyPem;
      Logger.d('[KeyManagerServiceWeb] RSA key pair generated');

      final salt = _crypto.generateSalt();
      final key = await _crypto.deriveKey(password, salt);
      final encrypted = await _crypto.encrypt(privatePem, key);
      Logger.d('[KeyManagerServiceWeb] Private key encrypted with password');

      await _storage.write(key: _pubKey(userId), value: publicPem);
      await _storage.write(key: _privKey(userId), value: encrypted);
      await _storage.write(key: _saltKey(userId), value: salt);
      _cachedPrivateKeyPem = privatePem;
      _cachedPrivateKeyUserId = userId;
      Logger.d('[KeyManagerServiceWeb] User keys stored successfully');
    } catch (e) {
      Logger.e('[KeyManagerServiceWeb] e generating user keys: $e');
      rethrow;
    }
  }

  Future<String?> getUserPublicKey({required String userId}) async {
    final pub = await _storage.read(key: _pubKey(userId));
    Logger.d(
      '[KeyManagerServiceWeb] getUserPublicKey($userId): '
      '${pub != null ? 'found' : 'not found'}',
    );
    return pub;
  }

  Future<void> saveUserPublicKey({
    required String userId,
    required String publicKeyPem,
  }) async {
    await _storage.write(key: _pubKey(userId), value: publicKeyPem);
    Logger.d('[KeyManagerServiceWeb] User public key saved for $userId');
  }

  Future<String?> getUserEncryptedPrivateKeyData({
    required String userId,
  }) async {
    return await _storage.read(key: _privKey(userId));
  }

  Future<void> storeUserPrivateKeyEncryptedWithPassword({
    required String userId,
    required String privateKeyPem,
    required String password,
    String? salt,
  }) async {
    final effectiveSalt = salt ?? _crypto.generateSalt();
    final derivedKey = await _crypto.deriveKey(password, effectiveSalt);
    final encrypted = await _crypto.encrypt(privateKeyPem, derivedKey);
    await _storage.write(key: _privKey(userId), value: encrypted);
    await _storage.write(key: _saltKey(userId), value: effectiveSalt);
    _cachedPrivateKeyPem = privateKeyPem;
    _cachedPrivateKeyUserId = userId;
    Logger.d(
      '[KeyManagerServiceWeb] User private key stored (encrypted with password) '
      'for $userId',
    );
  }

  Future<String?> getPrivateKeyPEM({
    required String userId,
    required String password,
  }) async {
    if (_cachedPrivateKeyPem != null && _cachedPrivateKeyUserId == userId) {
      Logger.d(
        '[KeyManagerServiceWeb] Returning cached private key PEM for $userId',
      );
      return _cachedPrivateKeyPem;
    }
    try {
      final encrypted = await _storage.read(key: _privKey(userId));
      final salt = await _storage.read(key: _saltKey(userId));
      if (encrypted == null || salt == null) {
        Logger.d(
          '[KeyManagerServiceWeb] Private key or salt not found in storage '
          'for $userId',
        );
        return null;
      }
      final key = await _crypto.deriveKey(password, salt);
      final pem = await _crypto.decrypt(encrypted, key);
      if (pem != null) {
        _cachedPrivateKeyPem = pem;
        _cachedPrivateKeyUserId = userId;
      }
      Logger.d(
        '[KeyManagerServiceWeb] Private key PEM '
        '${pem != null ? 'decrypted' : 'decryption failed'} for $userId',
      );
      return pem;
    } catch (e) {
      Logger.e('[KeyManagerServiceWeb] e getting private key PEM: $e');
      return null;
    }
  }

  Future<String?> decryptPrivateKeyWithPassword(
    String encryptedKey,
    String salt,
    String password,
  ) async {
    try {
      final key = await _crypto.deriveKey(password, salt);
      return await _crypto.decrypt(encryptedKey, key);
    } catch (e) {
      Logger.e(
        '[KeyManagerServiceWeb] e decrypting private key with password: $e',
      );
      return null;
    }
  }

  Future<bool> verifyKeyPairMatch({
    required String publicKeyPem,
    required String userId,
    required String password,
  }) async {
    try {
      final publicKey = await _importPublicKeyFromPem(publicKeyPem);

      final privatePem = await getPrivateKeyPEM(
        userId: userId,
        password: password,
      );
      if (privatePem == null) {
        Logger.d(
          '[KeyManagerServiceWeb] verifyKeyPairMatch: private key unavailable '
          'for $userId',
        );
        return false;
      }
      final privateKey = await _importPrivateKeyFromPem(privatePem);

      final testMessage = utf8.encode('vaultly:keypair:test');
      final encrypted = await publicKey.encryptBytes(testMessage);
      final decrypted = await privateKey.decryptBytes(encrypted);

      final matches = base64Encode(testMessage) == base64Encode(decrypted);
      Logger.d('[KeyManagerServiceWeb] verifyKeyPairMatch: $matches');
      return matches;
    } catch (e) {
      Logger.e('[KeyManagerServiceWeb] verifyKeyPairMatch error: $e');
      return false;
    }
  }

  Future<bool> verifyStoredKeyPairMatches({
    required String userId,
    required String password,
  }) async {
    final publicPem = await getUserPublicKey(userId: userId);
    if (publicPem == null || publicPem.isEmpty) {
      Logger.d(
        '[KeyManagerServiceWeb] verifyStoredKeyPairMatches($userId): no public key',
      );
      return false;
    }
    return verifyKeyPairMatch(
      publicKeyPem: publicPem,
      userId: userId,
      password: password,
    );
  }

  Future<void> clearUserKeys({required String userId}) async {
    Logger.d('[KeyManagerServiceWeb] Clearing user keys for $userId...');
    await _storage.delete(key: _pubKey(userId));
    await _storage.delete(key: _privKey(userId));
    await _storage.delete(key: _saltKey(userId));
    if (_cachedPrivateKeyUserId == userId) {
      _invalidateCache();
    }
    Logger.d('[KeyManagerServiceWeb] User keys cleared for $userId');
  }

  Future<void> promotePendingUserKeys({required String userId}) async {
    final pub = await _storage.read(key: _pubKey(pendingUserId));
    final priv = await _storage.read(key: _privKey(pendingUserId));
    final salt = await _storage.read(key: _saltKey(pendingUserId));

    if (pub == null || priv == null || salt == null) {
      Logger.d(
        '[KeyManagerServiceWeb] promotePendingUserKeys: pending keys not found',
      );
      return;
    }

    await _storage.write(key: _pubKey(userId), value: pub);
    await _storage.write(key: _privKey(userId), value: priv);
    await _storage.write(key: _saltKey(userId), value: salt);

    await _storage.delete(key: _pubKey(pendingUserId));
    await _storage.delete(key: _privKey(pendingUserId));
    await _storage.delete(key: _saltKey(pendingUserId));

    if (_cachedPrivateKeyUserId == pendingUserId) {
      _cachedPrivateKeyUserId = userId;
    }

    Logger.d('[KeyManagerServiceWeb] Pending keys promoted to user $userId');
  }

  Future<String> encryptWithPassword({
    required String userId,
    required String plaintext,
    required String password,
  }) async {
    final salt = await getUserSalt(userId: userId) ?? _crypto.generateSalt();
    final key = await _crypto.deriveKey(password, salt);
    return await _crypto.encrypt(plaintext, key);
  }

  Future<bool> hasDeviceKeys() async {
    final pub = await _storage.read(key: _devicePublicKey);
    final priv = await _storage.read(key: _devicePrivateKey);
    final exists = pub != null && priv != null;
    Logger.d('[KeyManagerServiceWeb] hasDeviceKeys: $exists');
    return exists;
  }

  Future<String> generateAndStoreDeviceKeyPair(String password) async {
    Logger.d('[KeyManagerServiceWeb] Generating device key pair...');
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
      Logger.d('[KeyManagerServiceWeb] Device keys stored successfully');
      return publicPem;
    } catch (e, stack) {
      Logger.e(
        '[KeyManagerServiceWeb] e generating device keys',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<String?> getDevicePublicKey() async {
    final pub = await _storage.read(key: _devicePublicKey);
    Logger.d(
      '[KeyManagerServiceWeb] getDevicePublicKey: '
      '${pub != null ? 'found' : 'not found'}',
    );
    return pub;
  }

  Future<String?> getDevicePrivateKeyPEM(String password) async {
    try {
      final encrypted = await _storage.read(key: _devicePrivateKey);
      final salt = await _storage.read(key: _deviceSalt);
      if (encrypted == null || salt == null) {
        Logger.d('[KeyManagerServiceWeb] Device private key PEM not found');
        return null;
      }
      final key = await _crypto.deriveKey(password, salt);
      final pem = await _crypto.decrypt(encrypted, key);
      Logger.d(
        '[KeyManagerServiceWeb] Device private key PEM '
        '${pem != null ? 'decrypted' : 'decryption failed'}',
      );
      return pem;
    } catch (e) {
      Logger.e('[KeyManagerServiceWeb] e getting device private key PEM: $e');
      return null;
    }
  }

  Future<bool> verifyStoredDeviceKeyPairMatches({
    required String password,
  }) async {
    final publicPem = await getDevicePublicKey();
    if (publicPem == null || publicPem.isEmpty) {
      Logger.d(
        '[KeyManagerServiceWeb] verifyStoredDeviceKeyPairMatches: no public key',
      );
      return false;
    }
    try {
      final publicKey = await _importPublicKeyFromPem(publicPem);
      final privatePem = await getDevicePrivateKeyPEM(password);
      if (privatePem == null) return false;
      final privateKey = await _importPrivateKeyFromPem(privatePem);

      final testMessage = utf8.encode('vaultly:device-keypair:test');
      final encrypted = await publicKey.encryptBytes(testMessage);
      final decrypted = await privateKey.decryptBytes(encrypted);
      final matches = base64Encode(testMessage) == base64Encode(decrypted);
      Logger.d(
        '[KeyManagerServiceWeb] verifyStoredDeviceKeyPairMatches: $matches',
      );
      return matches;
    } catch (e) {
      Logger.e(
        '[KeyManagerServiceWeb] verifyStoredDeviceKeyPairMatches error: $e',
      );
      return false;
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

  Future<void> clearKeys() async {
    Logger.d('[KeyManagerServiceWeb] Clearing device + pending keys...');
    await _storage.delete(key: _devicePublicKey);
    await _storage.delete(key: _devicePrivateKey);
    await _storage.delete(key: _deviceSalt);
    await _storage.delete(key: _pubKey(pendingUserId));
    await _storage.delete(key: _privKey(pendingUserId));
    await _storage.delete(key: _saltKey(pendingUserId));
    _invalidateCache();
    Logger.d('[KeyManagerServiceWeb] Device + pending keys cleared');
  }

  Future<void> clearAllKeys() async {
    await clearKeys();
    Logger.d('[KeyManagerServiceWeb] clearAllKeys completed');
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
      Logger.e('[_CryptoHelperWeb] e during decryption: $e');
      return null;
    }
  }
}
