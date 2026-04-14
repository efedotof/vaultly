// //[SecureStorageAdapter] для web
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class SecureStorageAdapter {
//   static final FlutterSecureStorage _secureStorage =
//       const FlutterSecureStorage();

//   static Future<void> write({
//     required String key,
//     required String value,
//   }) async {
//     await _secureStorage.write(key: key, value: value);
//   }

//   static Future<String?> read({required String key}) async {
//     return await _secureStorage.read(key: key);
//   }

//   static Future<void> delete({required String key}) async {
//     await _secureStorage.delete(key: key);
//   }
// }

//[SecureStorageAdapter] для macos -- временное решение, так как требуется Apple Developers сертификат. Расскоментировать для macos !!!

import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageAdapter {
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  static Future<void> write({
    required String key,
    required String value,
  }) async {
    if (Platform.isMacOS) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  static Future<String?> read({required String key}) async {
    if (Platform.isMacOS) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  static Future<void> delete({required String key}) async {
    if (Platform.isMacOS) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }
}
