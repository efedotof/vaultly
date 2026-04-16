import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart' as pc;
import 'package:basic_utils/basic_utils.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:vaulth_app/server/service/logger_service.dart';
import 'package:vaulth_app/storage/secure_storage_adapter.dart';

class KeyManagerService {
  final crypto = _CryptoHelper();

  static const _userPublicKey = 'user_public_key';
  static const _userPrivateKey = 'user_private_key';
  static const _userSalt = 'user_salt';

  static const _devicePublicKey = 'device_public_key';
  static const _devicePrivateKey = 'device_private_key';
  static const _deviceSalt = 'device_salt';

  pc.RSAPrivateKey? _cachedPrivateKey;

  Future<String?> getUserSalt() => SecureStorageAdapter.read(key: _userSalt);

  Future<String> generateAndStoreUserKeyPair(String password) async {
    LoggerService().debug('[KeyManagerService] Generating user key pair...');
    try {
      final pair = _generateRSAKeyPair();
      final publicPem = CryptoUtils.encodeRSAPublicKeyToPem(pair.publicKey);
      final privatePem = CryptoUtils.encodeRSAPrivateKeyToPem(pair.privateKey);
      LoggerService().debug('[KeyManagerService] RSA key pair generated');

      final salt = crypto.generateSalt();
      final key = await crypto.deriveKey(password, salt);
      final encrypted = await crypto.encrypt(privatePem, key);
      LoggerService().debug(
        '[KeyManagerService] Private key encrypted with password',
      );

      await SecureStorageAdapter.write(key: _userPublicKey, value: publicPem);
      await SecureStorageAdapter.write(key: _userPrivateKey, value: encrypted);
      await SecureStorageAdapter.write(key: _userSalt, value: salt);
      _cachedPrivateKey = pair.privateKey;
      LoggerService().debug(
        '[KeyManagerService] User keys stored successfully',
      );
      return publicPem;
    } catch (e) {
      LoggerService().error(
        '[KeyManagerService] ERROR generating user keys: $e',
      );
      rethrow;
    }
  }

  Future<String?> getUserPublicKey() async {
    final pub = await SecureStorageAdapter.read(key: _userPublicKey);
    LoggerService().debug(
      '[KeyManagerService] getUserPublicKey: ${pub != null ? 'found' : 'not found'}',
    );
    return pub;
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

  Future<String?> getPublicKey() async => getUserPublicKey();

  Future<String?> getDevicePrivateKeyPEM(String password) async {
    try {
      final encrypted = await SecureStorageAdapter.read(key: _devicePrivateKey);
      final salt = await SecureStorageAdapter.read(key: _deviceSalt);
      if (encrypted == null || salt == null) {
        LoggerService().debug(
          '[KeyManagerService] Device private key PEM not found',
        );
        return null;
      }
      final key = await crypto.deriveKey(password, salt);
      final pem = await crypto.decrypt(encrypted, key);
      LoggerService().debug(
        '[KeyManagerService] Device private key PEM ${pem != null ? 'decrypted' : 'decryption failed'}',
      );
      return pem;
    } catch (e) {
      LoggerService().error(
        '[KeyManagerService] ERROR getting device private key PEM: $e',
      );
      return null;
    }
  }

  Future<void> storeUserPrivateKeyEncryptedWithPassword(
    String privateKeyPem,
    String password, {
    String? salt,
  }) async {
    final effectiveSalt = salt ?? crypto.generateSalt();
    final key = await crypto.deriveKey(password, effectiveSalt);
    final encrypted = await crypto.encrypt(privateKeyPem, key);
    await SecureStorageAdapter.write(key: _userPrivateKey, value: encrypted);
    await SecureStorageAdapter.write(key: _userSalt, value: effectiveSalt);
    _cachedPrivateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
    LoggerService().debug(
      '[KeyManagerService] User private key stored (encrypted with password)',
    );
  }

  Future<pc.RSAPrivateKey?> loadUserPrivateKeyWithPassword(
    String password,
  ) async {
    final encrypted = await SecureStorageAdapter.read(key: _userPrivateKey);
    final salt = await SecureStorageAdapter.read(key: _userSalt);
    if (encrypted == null || salt == null) return null;
    final key = await crypto.deriveKey(password, salt);
    final pem = await crypto.decrypt(encrypted, key);
    if (pem == null) return null;
    return CryptoUtils.rsaPrivateKeyFromPem(pem);
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

  Future<pc.RSAPublicKey?> getDevicePublicKeyObject() async {
    final pem = await getDevicePublicKey();
    if (pem == null) return null;
    try {
      return CryptoUtils.rsaPublicKeyFromPem(pem);
    } catch (e) {
      LoggerService().error(
        '[KeyManagerService] ERROR parsing device public key from PEM: $e',
      );
      return null;
    }
  }

  Future<pc.RSAPrivateKey?> getDevicePrivateKeyObject(String password) async {
    final pem = await getDevicePrivateKeyPEM(password);
    if (pem == null) return null;
    try {
      return CryptoUtils.rsaPrivateKeyFromPem(pem);
    } catch (e) {
      LoggerService().error(
        '[KeyManagerService] ERROR parsing device private key from PEM: $e',
      );
      return null;
    }
  }

  Future<pc.RSAPrivateKey?> getPrivateKey(String password) async {
    if (_cachedPrivateKey != null) {
      LoggerService().debug('[KeyManagerService] Returning cached private key');
      return _cachedPrivateKey;
    }
    try {
      final encrypted = await SecureStorageAdapter.read(key: _userPrivateKey);
      final salt = await SecureStorageAdapter.read(key: _userSalt);
      if (encrypted == null || salt == null) {
        LoggerService().debug(
          '[KeyManagerService] Private key or salt not found in storage',
        );
        return null;
      }
      LoggerService().debug(
        '[KeyManagerService] Found encrypted private key (length ${encrypted.length}) and salt',
      );
      final key = await crypto.deriveKey(password, salt);
      final pem = await crypto.decrypt(encrypted, key);
      LoggerService().debug(
        '[KeyManagerService] Decrypted PEM length: ${pem?.length}',
      );
      if (pem == null || pem.isEmpty) {
        LoggerService().debug(
          '[KeyManagerService] Failed to decrypt private key (wrong password?)',
        );
        return null;
      }
      try {
        final privateKey = CryptoUtils.rsaPrivateKeyFromPem(pem);
        _cachedPrivateKey = privateKey;
        LoggerService().debug(
          '[KeyManagerService] Private key parsed successfully',
        );
        return privateKey;
      } catch (e, stack) {
        LoggerService().error(
          '[KeyManagerService] Failed to parse PEM',
          error: e,
          stackTrace: stack,
        );
        return null;
      }
    } catch (e) {
      LoggerService().error(
        '[KeyManagerService] ERROR loading private key: $e',
      );
      return null;
    }
  }

  Future<String?> getPrivateKeyPEM(String password) async {
    try {
      final encrypted = await SecureStorageAdapter.read(key: _userPrivateKey);
      final salt = await SecureStorageAdapter.read(key: _userSalt);
      if (encrypted == null || salt == null) {
        LoggerService().debug('[KeyManagerService] Private key PEM not found');
        return null;
      }
      final key = await crypto.deriveKey(password, salt);
      final pem = await crypto.decrypt(encrypted, key);
      LoggerService().debug(
        '[KeyManagerService] Private key PEM ${pem != null ? 'decrypted' : 'decryption failed'}',
      );
      return pem;
    } catch (e) {
      LoggerService().error(
        '[KeyManagerService] ERROR getting private key PEM: $e',
      );
      return null;
    }
  }

  Future<bool> hasDeviceKeys() async {
    final pub = await SecureStorageAdapter.read(key: _devicePublicKey);
    final priv = await SecureStorageAdapter.read(key: _devicePrivateKey);
    final exists = pub != null && priv != null;
    LoggerService().debug('[KeyManagerService] hasDeviceKeys: $exists');
    return exists;
  }

  Future<String> generateAndStoreDeviceKeyPair(String password) async {
    LoggerService().debug('[KeyManagerService] Generating device key pair...');
    try {
      LoggerService().debug(
        '[KeyManagerService] Step 1: generating RSA key pair...',
      );
      final pair = _generateRSAKeyPair();
      LoggerService().debug('[KeyManagerService] Step 2: converting to PEM...');
      final publicPem = CryptoUtils.encodeRSAPublicKeyToPem(pair.publicKey);
      final privatePem = CryptoUtils.encodeRSAPrivateKeyToPem(pair.privateKey);
      LoggerService().debug('[KeyManagerService] Step 3: generating salt...');
      final salt = crypto.generateSalt();
      LoggerService().debug(
        '[KeyManagerService] Step 4: deriving key from password...',
      );
      final key = await crypto.deriveKey(password, salt);
      LoggerService().debug(
        '[KeyManagerService] Step 5: encrypting private key...',
      );
      final encrypted = await crypto.encrypt(privatePem, key);
      LoggerService().debug(
        '[KeyManagerService] Step 6: storing to secure storage...',
      );
      await SecureStorageAdapter.write(key: _devicePublicKey, value: publicPem);
      await SecureStorageAdapter.write(
        key: _devicePrivateKey,
        value: encrypted,
      );
      await SecureStorageAdapter.write(key: _deviceSalt, value: salt);
      LoggerService().debug(
        '[KeyManagerService] Device keys stored successfully',
      );
      return publicPem;
    } catch (e, stack) {
      LoggerService().error(
        '[KeyManagerService] ERROR generating device keys',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
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
      LoggerService().error(
        '[KeyManagerService] ERROR decrypting private key: $e',
      );
      return null;
    }
  }

  Future<String?> getDevicePublicKey() async {
    final pub = await SecureStorageAdapter.read(key: _devicePublicKey);
    LoggerService().debug(
      '[KeyManagerService] getDevicePublicKey: ${pub != null ? 'found' : 'not found'}',
    );
    return pub;
  }

  Future<Map<String, String?>?> getDeviceEncryptedPrivateKeyData() async {
    final encrypted = await SecureStorageAdapter.read(key: _devicePrivateKey);
    final salt = await SecureStorageAdapter.read(key: _deviceSalt);
    if (encrypted == null || salt == null) {
      LoggerService().debug(
        '[KeyManagerService] Device encrypted private key data not found',
      );
      return null;
    }
    LoggerService().debug(
      '[KeyManagerService] Device encrypted private key data retrieved',
    );
    return {'encrypted': encrypted, 'salt': salt};
  }

  Future<void> clearKeys() async {
    LoggerService().debug('[KeyManagerService] Clearing all keys...');
    await SecureStorageAdapter.delete(key: _userPublicKey);
    await SecureStorageAdapter.delete(key: _userPrivateKey);
    await SecureStorageAdapter.delete(key: _userSalt);
    await SecureStorageAdapter.delete(key: _devicePublicKey);
    await SecureStorageAdapter.delete(key: _devicePrivateKey);
    await SecureStorageAdapter.delete(key: _deviceSalt);
    _cachedPrivateKey = null;
    LoggerService().debug('[KeyManagerService] All keys cleared');
  }

  Future<void> clearAllKeys() async {
    await clearKeys();
    LoggerService().debug('[KeyManagerService] clearAllKeys completed');
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

  Future<pc.RSAPublicKey?> getUserPublicKeyObject() async {
    final pem = await getUserPublicKey();
    if (pem == null) return null;
    try {
      return CryptoUtils.rsaPublicKeyFromPem(pem);
    } catch (e) {
      LoggerService().error(
        '[KeyManagerService] ERROR parsing public key from PEM: $e',
      );
      return null;
    }
  }

  Future<String?> getUserEncryptedPrivateKeyData() async {
    return await SecureStorageAdapter.read(key: _userPrivateKey);
  }

  Future<void> saveUserPublicKey(String publicKeyPem) async {
    await SecureStorageAdapter.write(key: _userPublicKey, value: publicKeyPem);
    LoggerService().debug('[KeyManagerService] User public key saved');
  }

  Future<void> clearUserKeys() async {
    LoggerService().debug('[KeyManagerService] Clearing user keys only...');
    await SecureStorageAdapter.delete(key: _userPublicKey);
    await SecureStorageAdapter.delete(key: _userPrivateKey);
    await SecureStorageAdapter.delete(key: _userSalt);
    _cachedPrivateKey = null;
    LoggerService().debug(
      '[KeyManagerService] User keys cleared (device keys preserved)',
    );
  }

  Future<String> encryptWithPassword(String plaintext, String password) async {
    final salt = await getUserSalt() ?? crypto.generateSalt();
    final key = await crypto.deriveKey(password, salt);
    return await crypto.encrypt(plaintext, key);
  }
}

class _CryptoHelper {
  final _aes = crypto.AesGcm.with256bits();

  String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt = base64Encode(bytes);
    LoggerService().debug('[_CryptoHelper] Generated salt');
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
    final nonce = iv;
    final box = await _aes.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );
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
    LoggerService().debug('[_CryptoHelper] Key derived from password');
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
    LoggerService().debug('[_CryptoHelper] Text encrypted');
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
      LoggerService().debug('[_CryptoHelper] Text decrypted successfully');
      return utf8.decode(decrypted);
    } catch (e) {
      LoggerService().error('[_CryptoHelper] ERROR during decryption: $e');
      return null;
    }
  }
}
