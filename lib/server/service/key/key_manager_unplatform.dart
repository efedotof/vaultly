import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:basic_utils/basic_utils.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:vaulth_app/server/service/logger/logger.dart';
import 'package:vaulth_app/storage/secure_storage_adapter.dart';

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

  final crypto = _CryptoHelper();

  static const String pendingUserId = '__pending__';

  static String _pubKey(String userId) => 'user_public_key:$userId';
  static String _privKey(String userId) => 'user_private_key:$userId';
  static String _saltKey(String userId) => 'user_salt:$userId';

  static const _devicePublicKey = 'device_public_key';
  static const _devicePrivateKey = 'device_private_key';
  static const _deviceSalt = 'device_salt';

  pc.RSAPrivateKey? _cachedPrivateKey;
  String? _cachedPrivateKeyUserId;

  void _invalidateCache() {
    _cachedPrivateKey = null;
    _cachedPrivateKeyUserId = null;
  }

  Future<String?> getUserSalt({required String userId}) =>
      SecureStorageAdapter.read(key: _saltKey(userId));

  Future<void> generateAndStoreUserKeyPair({
    required String userId,
    required String password,
  }) async {
    Logger.d('[KeyManagerService] Generating user key pair for $userId...');
    try {
      final pair = _generateRSAKeyPair();
      final publicPem = CryptoUtils.encodeRSAPublicKeyToPem(pair.publicKey);
      final privatePem = CryptoUtils.encodeRSAPrivateKeyToPem(pair.privateKey);
      Logger.d('[KeyManagerService] RSA key pair generated');

      final salt = crypto.generateSalt();
      final key = await crypto.deriveKey(password, salt);
      final encrypted = await crypto.encrypt(privatePem, key);
      Logger.d('[KeyManagerService] Private key encrypted with password');

      await SecureStorageAdapter.write(key: _pubKey(userId), value: publicPem);
      await SecureStorageAdapter.write(key: _privKey(userId), value: encrypted);
      await SecureStorageAdapter.write(key: _saltKey(userId), value: salt);
      _cachedPrivateKey = pair.privateKey;
      _cachedPrivateKeyUserId = userId;
      Logger.d('[KeyManagerService] User keys stored successfully');
    } catch (e) {
      Logger.e('[KeyManagerService] e generating user keys: $e');
      rethrow;
    }
  }

  Future<String?> getUserPublicKey({required String userId}) async {
    final pub = await SecureStorageAdapter.read(key: _pubKey(userId));
    Logger.d(
      '[KeyManagerService] getUserPublicKey($userId): '
      '${pub != null ? 'found' : 'not found'}',
    );
    return pub;
  }

  Future<void> saveUserPublicKey({
    required String userId,
    required String publicKeyPem,
  }) async {
    await SecureStorageAdapter.write(key: _pubKey(userId), value: publicKeyPem);
    Logger.d('[KeyManagerService] User public key saved for $userId');
  }

  Future<pc.RSAPublicKey?> getUserPublicKeyObject({
    required String userId,
  }) async {
    final pem = await getUserPublicKey(userId: userId);
    if (pem == null) return null;
    try {
      return CryptoUtils.rsaPublicKeyFromPem(pem);
    } catch (e) {
      Logger.e('[KeyManagerService] e parsing public key from PEM: $e');
      return null;
    }
  }

  Future<String?> getUserEncryptedPrivateKeyData({
    required String userId,
  }) async {
    return await SecureStorageAdapter.read(key: _privKey(userId));
  }

  Future<void> storeUserPrivateKeyEncryptedWithPassword({
    required String userId,
    required String privateKeyPem,
    required String password,
    String? salt,
  }) async {
    final effectiveSalt = salt ?? crypto.generateSalt();
    final key = await crypto.deriveKey(password, effectiveSalt);
    final encrypted = await crypto.encrypt(privateKeyPem, key);
    await SecureStorageAdapter.write(key: _privKey(userId), value: encrypted);
    await SecureStorageAdapter.write(
      key: _saltKey(userId),
      value: effectiveSalt,
    );
    _cachedPrivateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
    _cachedPrivateKeyUserId = userId;
    Logger.d(
      '[KeyManagerService] User private key stored (encrypted with password)',
    );
  }

  Future<pc.RSAPrivateKey?> loadUserPrivateKeyWithPassword({
    required String userId,
    required String password,
  }) async {
    final encrypted = await SecureStorageAdapter.read(key: _privKey(userId));
    final salt = await SecureStorageAdapter.read(key: _saltKey(userId));
    if (encrypted == null || salt == null) return null;
    final key = await crypto.deriveKey(password, salt);
    final pem = await crypto.decrypt(encrypted, key);
    if (pem == null) return null;
    return CryptoUtils.rsaPrivateKeyFromPem(pem);
  }

  Future<pc.RSAPrivateKey?> getPrivateKey({
    required String userId,
    required String password,
  }) async {
    if (_cachedPrivateKey != null && _cachedPrivateKeyUserId == userId) {
      Logger.d('[KeyManagerService] Returning cached private key for $userId');
      return _cachedPrivateKey;
    }
    try {
      final encrypted = await SecureStorageAdapter.read(key: _privKey(userId));
      final salt = await SecureStorageAdapter.read(key: _saltKey(userId));
      if (encrypted == null || salt == null) {
        Logger.d(
          '[KeyManagerService] Private key or salt not found in storage '
          'for $userId',
        );
        return null;
      }
      Logger.d(
        '[KeyManagerService] Found encrypted private key '
        '(length ${encrypted.length}) and salt for $userId',
      );
      final key = await crypto.deriveKey(password, salt);
      final pem = await crypto.decrypt(encrypted, key);
      Logger.d('[KeyManagerService] Decrypted PEM length: ${pem?.length}');
      if (pem == null || pem.isEmpty) {
        Logger.d(
          '[KeyManagerService] Failed to decrypt private key (wrong password?)',
        );
        return null;
      }
      try {
        final privateKey = CryptoUtils.rsaPrivateKeyFromPem(pem);
        _cachedPrivateKey = privateKey;
        _cachedPrivateKeyUserId = userId;
        Logger.d('[KeyManagerService] Private key parsed successfully');
        return privateKey;
      } catch (e, stack) {
        Logger.e(
          '[KeyManagerService] Failed to parse PEM',
          error: e,
          stackTrace: stack,
        );
        return null;
      }
    } catch (e) {
      Logger.e('[KeyManagerService] e loading private key: $e');
      return null;
    }
  }

  Future<String?> getPrivateKeyPEM({
    required String userId,
    required String password,
  }) async {
    try {
      final encrypted = await SecureStorageAdapter.read(key: _privKey(userId));
      final salt = await SecureStorageAdapter.read(key: _saltKey(userId));
      if (encrypted == null || salt == null) {
        Logger.d('[KeyManagerService] Private key PEM not found for $userId');
        return null;
      }
      final key = await crypto.deriveKey(password, salt);
      final pem = await crypto.decrypt(encrypted, key);
      Logger.d(
        '[KeyManagerService] Private key PEM '
        '${pem != null ? 'decrypted' : 'decryption failed'}',
      );
      return pem;
    } catch (e) {
      Logger.e('[KeyManagerService] e getting private key PEM: $e');
      return null;
    }
  }

  Future<bool> verifyKeyPairMatch({
    required String publicKeyPem,
    required String userId,
    required String password,
  }) async {
    try {
      final publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);
      final privateKey = await getPrivateKey(
        userId: userId,
        password: password,
      );

      if (privateKey == null) {
        Logger.d(
          '[KeyManagerService] verifyKeyPairMatch: private key unavailable '
          '(wrong password or missing)',
        );
        return false;
      }

      final testMessage = Uint8List.fromList(
        utf8.encode('vaultly:keypair:test'),
      );
      final encrypted = _rsaOaepEncrypt(testMessage, publicKey);
      final decrypted = _rsaOaepDecrypt(encrypted, privateKey);

      final matches = _bytesEqual(testMessage, decrypted);
      Logger.d('[KeyManagerService] verifyKeyPairMatch: $matches');
      return matches;
    } catch (e, s) {
      Logger.e(
        '[KeyManagerService] verifyKeyPairMatch error',
        error: e,
        stackTrace: s,
      );
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
        '[KeyManagerService] verifyStoredKeyPairMatches($userId): no public key',
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
    Logger.d('[KeyManagerService] Clearing user keys for $userId...');
    await SecureStorageAdapter.delete(key: _pubKey(userId));
    await SecureStorageAdapter.delete(key: _privKey(userId));
    await SecureStorageAdapter.delete(key: _saltKey(userId));
    if (_cachedPrivateKeyUserId == userId) {
      _invalidateCache();
    }
    Logger.d('[KeyManagerService] User keys cleared for $userId');
  }

  Future<void> promotePendingUserKeys({required String userId}) async {
    final pub = await SecureStorageAdapter.read(key: _pubKey(pendingUserId));
    final priv = await SecureStorageAdapter.read(key: _privKey(pendingUserId));
    final salt = await SecureStorageAdapter.read(key: _saltKey(pendingUserId));

    if (pub == null || priv == null || salt == null) {
      Logger.d(
        '[KeyManagerService] promotePendingUserKeys: pending keys not found',
      );
      return;
    }

    await SecureStorageAdapter.write(key: _pubKey(userId), value: pub);
    await SecureStorageAdapter.write(key: _privKey(userId), value: priv);
    await SecureStorageAdapter.write(key: _saltKey(userId), value: salt);

    await SecureStorageAdapter.delete(key: _pubKey(pendingUserId));
    await SecureStorageAdapter.delete(key: _privKey(pendingUserId));
    await SecureStorageAdapter.delete(key: _saltKey(pendingUserId));

    if (_cachedPrivateKeyUserId == pendingUserId) {
      _cachedPrivateKeyUserId = userId;
    }

    Logger.d('[KeyManagerService] Pending keys promoted to user $userId');
  }

  Future<String> encryptWithPassword({
    required String userId,
    required String plaintext,
    required String password,
  }) async {
    final salt = await getUserSalt(userId: userId) ?? crypto.generateSalt();
    final key = await crypto.deriveKey(password, salt);
    return await crypto.encrypt(plaintext, key);
  }

  Future<String?> getDevicePrivateKeyPEM(String password) async {
    try {
      final encrypted = await SecureStorageAdapter.read(key: _devicePrivateKey);
      final salt = await SecureStorageAdapter.read(key: _deviceSalt);
      if (encrypted == null || salt == null) {
        Logger.d('[KeyManagerService] Device private key PEM not found');
        return null;
      }
      final key = await crypto.deriveKey(password, salt);
      final pem = await crypto.decrypt(encrypted, key);
      Logger.d(
        '[KeyManagerService] Device private key PEM '
        '${pem != null ? 'decrypted' : 'decryption failed'}',
      );
      return pem;
    } catch (e) {
      Logger.e('[KeyManagerService] e getting device private key PEM: $e');
      return null;
    }
  }

  Future<bool> hasDeviceKeys() async {
    final pub = await SecureStorageAdapter.read(key: _devicePublicKey);
    final priv = await SecureStorageAdapter.read(key: _devicePrivateKey);
    final exists = pub != null && priv != null;
    Logger.d('[KeyManagerService] hasDeviceKeys: $exists');
    return exists;
  }

  Future<String> generateAndStoreDeviceKeyPair(String password) async {
    Logger.d('[KeyManagerService] Generating device key pair...');
    try {
      final pair = _generateRSAKeyPair();
      final publicPem = CryptoUtils.encodeRSAPublicKeyToPem(pair.publicKey);
      final privatePem = CryptoUtils.encodeRSAPrivateKeyToPem(pair.privateKey);
      final salt = crypto.generateSalt();
      final key = await crypto.deriveKey(password, salt);
      final encrypted = await crypto.encrypt(privatePem, key);
      await SecureStorageAdapter.write(key: _devicePublicKey, value: publicPem);
      await SecureStorageAdapter.write(
        key: _devicePrivateKey,
        value: encrypted,
      );
      await SecureStorageAdapter.write(key: _deviceSalt, value: salt);
      Logger.d('[KeyManagerService] Device keys stored successfully');
      return publicPem;
    } catch (e, stack) {
      Logger.e(
        '[KeyManagerService] e generating device keys',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<String?> getDevicePublicKey() async {
    final pub = await SecureStorageAdapter.read(key: _devicePublicKey);
    Logger.d(
      '[KeyManagerService] getDevicePublicKey: '
      '${pub != null ? 'found' : 'not found'}',
    );
    return pub;
  }

  Future<pc.RSAPublicKey?> getDevicePublicKeyObject() async {
    final pem = await getDevicePublicKey();
    if (pem == null) return null;
    try {
      return CryptoUtils.rsaPublicKeyFromPem(pem);
    } catch (e) {
      Logger.e('[KeyManagerService] e parsing device public key: $e');
      return null;
    }
  }

  Future<pc.RSAPrivateKey?> getDevicePrivateKeyObject(String password) async {
    final pem = await getDevicePrivateKeyPEM(password);
    if (pem == null) return null;
    try {
      return CryptoUtils.rsaPrivateKeyFromPem(pem);
    } catch (e) {
      Logger.e('[KeyManagerService] e parsing device private key: $e');
      return null;
    }
  }

  Future<Map<String, String?>?> getDeviceEncryptedPrivateKeyData() async {
    final encrypted = await SecureStorageAdapter.read(key: _devicePrivateKey);
    final salt = await SecureStorageAdapter.read(key: _deviceSalt);
    if (encrypted == null || salt == null) {
      Logger.d(
        '[KeyManagerService] Device encrypted private key data not found',
      );
      return null;
    }
    Logger.d('[KeyManagerService] Device encrypted private key data retrieved');
    return {'encrypted': encrypted, 'salt': salt};
  }

  Future<bool> verifyStoredDeviceKeyPairMatches({
    required String password,
  }) async {
    final publicPem = await getDevicePublicKey();
    if (publicPem == null || publicPem.isEmpty) {
      Logger.d(
        '[KeyManagerService] verifyStoredDeviceKeyPairMatches: no public key',
      );
      return false;
    }
    try {
      final publicKey = CryptoUtils.rsaPublicKeyFromPem(publicPem);
      final privateKey = await getDevicePrivateKeyObject(password);
      if (privateKey == null) return false;

      final testMessage = Uint8List.fromList(
        utf8.encode('vaultly:device-keypair:test'),
      );
      final encrypted = _rsaOaepEncrypt(testMessage, publicKey);
      final decrypted = _rsaOaepDecrypt(encrypted, privateKey);
      final matches = _bytesEqual(testMessage, decrypted);
      Logger.d(
        '[KeyManagerService] verifyStoredDeviceKeyPairMatches: $matches',
      );
      return matches;
    } catch (e, s) {
      Logger.e(
        '[KeyManagerService] verifyStoredDeviceKeyPairMatches error',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  Future<String> hybridEncryptWithPublicKey(
    String data,
    pc.RSAPublicKey publicKey,
  ) async {
    final aesKey = crypto.generateAesKey();
    final iv = crypto.generateIv();
    final encryptedData = await crypto.encryptAesGcm(
      utf8.encode(data),
      aesKey,
      iv,
    );
    final encryptedAesKey = _rsaOaepEncrypt(aesKey, publicKey);
    final result = {
      'encryptedKey': base64Encode(encryptedAesKey),
      'iv': base64Encode(iv),
      'ciphertext': base64Encode(encryptedData),
    };
    return jsonEncode(result);
  }

  Future<String> hybridDecryptWithPrivateKey(
    String encryptedPackage,
    pc.RSAPrivateKey privateKey,
  ) async {
    final json = jsonDecode(encryptedPackage);
    final encryptedAesKey = base64Decode(json['encryptedKey']);
    final iv = base64Decode(json['iv']);
    final ciphertext = base64Decode(json['ciphertext']);
    final aesKey = _rsaOaepDecrypt(encryptedAesKey, privateKey);
    final decrypted = await crypto.decryptAesGcm(ciphertext, aesKey, iv);
    return utf8.decode(decrypted);
  }

  Future<String> encryptWithPublicKey(
    String data,
    pc.RSAPublicKey publicKey,
  ) async {
    final bytes = utf8.encode(data);
    final oaep = pc.OAEPEncoding.withSHA256(pc.RSAEngine());
    oaep.init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey));
    final encrypted = oaep.process(Uint8List.fromList(bytes));
    return base64Encode(encrypted);
  }

  Future<String> decryptWithPrivateKey(
    String encryptedBase64,
    pc.RSAPrivateKey privateKey,
  ) async {
    final encrypted = base64Decode(encryptedBase64);
    final oaep = pc.OAEPEncoding.withSHA256(pc.RSAEngine());
    oaep.init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privateKey));
    final decrypted = oaep.process(encrypted);
    return utf8.decode(decrypted);
  }

  Future<String?> decryptPrivateKeyWithPassword(
    String encryptedKey,
    String salt,
    String password,
  ) async {
    try {
      final key = await crypto.deriveKey(password, salt);
      return await crypto.decrypt(encryptedKey, key);
    } catch (e) {
      Logger.e('[KeyManagerService] e decrypting private key: $e');
      return null;
    }
  }

  Future<void> clearKeys() async {
    Logger.d('[KeyManagerService] Clearing device + pending keys...');
    await SecureStorageAdapter.delete(key: _devicePublicKey);
    await SecureStorageAdapter.delete(key: _devicePrivateKey);
    await SecureStorageAdapter.delete(key: _deviceSalt);
    await SecureStorageAdapter.delete(key: _pubKey(pendingUserId));
    await SecureStorageAdapter.delete(key: _privKey(pendingUserId));
    await SecureStorageAdapter.delete(key: _saltKey(pendingUserId));
    _invalidateCache();
    Logger.d('[KeyManagerService] Device + pending keys cleared');
  }

  Future<void> clearAllKeys() async {
    await clearKeys();
    Logger.d('[KeyManagerService] clearAllKeys completed');
  }

  Uint8List _rsaOaepEncrypt(Uint8List data, pc.RSAPublicKey publicKey) {
    final oaep = pc.OAEPEncoding.withSHA256(pc.RSAEngine());
    oaep.init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey));
    return oaep.process(data);
  }

  Uint8List _rsaOaepDecrypt(Uint8List encrypted, pc.RSAPrivateKey privateKey) {
    final oaep = pc.OAEPEncoding.withSHA256(pc.RSAEngine());
    oaep.init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privateKey));
    return oaep.process(encrypted);
  }

  pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>
  _generateRSAKeyPair() {
    final secureRandom = _getSecureRandom();
    final params = pc.RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64);
    final generator = pc.RSAKeyGenerator()
      ..init(pc.ParametersWithRandom(params, secureRandom));
    final pair = generator.generateKeyPair();
    return pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>(
      pair.publicKey as pc.RSAPublicKey,
      pair.privateKey as pc.RSAPrivateKey,
    );
  }

  pc.SecureRandom _getSecureRandom() {
    final secureRandom = pc.FortunaRandom();
    final seed = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seed)));
    return secureRandom;
  }

  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

class _CryptoHelper {
  final _aes = crypto.AesGcm.with256bits();

  String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt = base64Encode(bytes);
    Logger.d('[_CryptoHelper] Generated salt');
    return salt;
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
    final secretKey = crypto.SecretKey(key);
    final box = await _aes.encrypt(plaintext, secretKey: secretKey, nonce: iv);
    return Uint8List.fromList(box.cipherText + box.mac.bytes);
  }

  Future<Uint8List> decryptAesGcm(
    Uint8List ciphertext,
    Uint8List key,
    Uint8List iv,
  ) async {
    final macBytes = ciphertext.sublist(ciphertext.length - 16);
    final actualCiphertext = ciphertext.sublist(0, ciphertext.length - 16);
    final secretKey = crypto.SecretKey(key);
    final box = crypto.SecretBox(
      actualCiphertext,
      nonce: iv,
      mac: crypto.Mac(macBytes),
    );
    final decrypted = await _aes.decrypt(box, secretKey: secretKey);
    return Uint8List.fromList(decrypted);
  }

  Future<crypto.SecretKey> deriveKey(String password, String salt) async {
    final pbkdf2 = crypto.Pbkdf2(
      macAlgorithm: crypto.Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: crypto.SecretKey(utf8.encode(password)),
      nonce: base64Decode(salt),
    );
    Logger.d('[_CryptoHelper] Key derived from password');
    return key;
  }

  Future<String> encrypt(String text, crypto.SecretKey key) async {
    final nonce = List<int>.generate(12, (_) => Random.secure().nextInt(256));
    final box = await _aes.encrypt(
      utf8.encode(text),
      secretKey: key,
      nonce: nonce,
    );
    final result = jsonEncode({
      'cipherText': base64Encode(box.cipherText),
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
    });
    Logger.d('[_CryptoHelper] Text encrypted');
    return result;
  }

  Future<String?> decrypt(String data, crypto.SecretKey key) async {
    try {
      final json = jsonDecode(data);
      final box = crypto.SecretBox(
        base64Decode(json['cipherText']),
        nonce: base64Decode(json['nonce']),
        mac: crypto.Mac(base64Decode(json['mac'])),
      );
      final decrypted = await _aes.decrypt(box, secretKey: key);
      Logger.d('[_CryptoHelper] Text decrypted successfully');
      return utf8.decode(decrypted);
    } catch (e) {
      Logger.e('[_CryptoHelper] e during decryption: $e');
      return null;
    }
  }
}
