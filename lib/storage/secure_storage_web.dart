// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

class SecureStorageAdapter {
  static Future<void> write({
    required String key,
    required String value,
  }) async {
    html.window.localStorage[key] = value;
  }

  static Future<String?> read({required String key}) async {
    return html.window.localStorage[key];
  }

  static Future<void> delete({required String key}) async {
    html.window.localStorage.remove(key);
  }
}
