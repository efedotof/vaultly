import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:vaulth_app/server/model/auth/auth_response/auth_response.dart';
import 'package:vaulth_app/storage/secure_storage_adapter.dart';

class AuthLocalStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'email';
  static const String _usernameKey = 'username';
  static const String _storageUsedKey = 'storage_used';
  static const String _storageLimitKey = 'storage_limit';
  static const String _rolesKey = 'roles';
  static const String _passwordEncryptedKey = 'password_encrypted';
  static const String _masterKeyKey = 'master_key';

  static crypto.SecretKey? _cachedMasterKey;

  Future<crypto.SecretKey> _getOrCreateMasterKey() async {
    if (_cachedMasterKey != null) return _cachedMasterKey!;
    final storedKeyBase64 = await SecureStorageAdapter.read(key: _masterKeyKey);
    if (storedKeyBase64 != null) {
      final keyBytes = base64Decode(storedKeyBase64);
      _cachedMasterKey = crypto.SecretKey(keyBytes);
      return _cachedMasterKey!;
    }
    final keyBytes = Uint8List(32);
    final random = Random.secure();
    for (int i = 0; i < 32; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    final key = crypto.SecretKey(keyBytes);
    await SecureStorageAdapter.write(
      key: _masterKeyKey,
      value: base64Encode(keyBytes),
    );
    _cachedMasterKey = key;
    return key;
  }

  Future<void> savePassword(String password) async {
    final masterKey = await _getOrCreateMasterKey();
    final random = Random.secure();
    final nonce = Uint8List(12);
    for (int i = 0; i < 12; i++) {
      nonce[i] = random.nextInt(256);
    }
    final box = await crypto.AesGcm.with256bits().encrypt(
      utf8.encode(password),
      secretKey: masterKey,
      nonce: nonce,
    );
    final payload = jsonEncode({
      'data': base64Encode(box.cipherText),
      'nonce': base64Encode(nonce),
      'mac': base64Encode(box.mac.bytes),
    });
    await SecureStorageAdapter.write(
      key: _passwordEncryptedKey,
      value: payload,
    );
  }

  Future<String?> getPassword() async {
    final payload = await SecureStorageAdapter.read(key: _passwordEncryptedKey);
    if (payload == null) return null;
    final json = jsonDecode(payload);
    final encryptedData = base64Decode(json['data']);
    final nonce = base64Decode(json['nonce']);
    final mac = base64Decode(json['mac']);
    final masterKey = await _getOrCreateMasterKey();
    final box = crypto.SecretBox(
      encryptedData,
      nonce: nonce,
      mac: crypto.Mac(mac),
    );
    final decrypted = await crypto.AesGcm.with256bits().decrypt(
      box,
      secretKey: masterKey,
    );
    return utf8.decode(decrypted);
  }

  Future<void> deletePassword() async {
    await SecureStorageAdapter.delete(key: _passwordEncryptedKey);
  }

  Future<void> saveAuthData(AuthResponse response) async {
    await SecureStorageAdapter.write(
      key: _accessTokenKey,
      value: response.accessToken ?? "",
    );
    await SecureStorageAdapter.write(
      key: _refreshTokenKey,
      value: response.refreshToken ?? "",
    );
    await SecureStorageAdapter.write(key: _userIdKey, value: response.userId);
    await SecureStorageAdapter.write(
      key: _emailKey,
      value: response.email ?? "",
    );
    await SecureStorageAdapter.write(
      key: _usernameKey,
      value: response.username,
    );
    await SecureStorageAdapter.write(
      key: _storageUsedKey,
      value: response.storageUsed.toString(),
    );
    await SecureStorageAdapter.write(
      key: _storageLimitKey,
      value: response.storageLimit.toString(),
    );
    await SecureStorageAdapter.write(
      key: _rolesKey,
      value: response.roles.join(','),
    );
  }

  Future<AuthResponse?> loadAuthData() async {
    final accessToken = await SecureStorageAdapter.read(key: _accessTokenKey);
    final refreshToken = await SecureStorageAdapter.read(key: _refreshTokenKey);
    final userId = await SecureStorageAdapter.read(key: _userIdKey);
    final email = await SecureStorageAdapter.read(key: _emailKey);
    final username = await SecureStorageAdapter.read(key: _usernameKey);
    final storageUsedStr = await SecureStorageAdapter.read(
      key: _storageUsedKey,
    );
    final storageLimitStr = await SecureStorageAdapter.read(
      key: _storageLimitKey,
    );
    final rolesStr = await SecureStorageAdapter.read(key: _rolesKey);

    if (accessToken == null ||
        refreshToken == null ||
        userId == null ||
        email == null ||
        username == null ||
        storageUsedStr == null ||
        storageLimitStr == null ||
        rolesStr == null) {
      return null;
    }
    return AuthResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      email: email,
      username: username,
      storageUsed: int.parse(storageUsedStr),
      storageLimit: int.parse(storageLimitStr),
      roles: rolesStr.split(',').toSet(),
    );
  }

  Future<String?> getAccessToken() =>
      SecureStorageAdapter.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() =>
      SecureStorageAdapter.read(key: _refreshTokenKey);
  Future<String?> getUserId() => SecureStorageAdapter.read(key: _userIdKey);

  Future<void> clearAuthData() async {
    await SecureStorageAdapter.delete(key: _accessTokenKey);
    await SecureStorageAdapter.delete(key: _refreshTokenKey);
    await SecureStorageAdapter.delete(key: _userIdKey);
    await SecureStorageAdapter.delete(key: _emailKey);
    await SecureStorageAdapter.delete(key: _usernameKey);
    await SecureStorageAdapter.delete(key: _storageUsedKey);
    await SecureStorageAdapter.delete(key: _storageLimitKey);
    await SecureStorageAdapter.delete(key: _rolesKey);
    await deletePassword();
  }
}
