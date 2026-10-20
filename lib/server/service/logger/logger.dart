import 'package:flutter/foundation.dart';

class Logger {
  Logger._();

  static bool get _enabled => !kReleaseMode;

  static void d(String message, {String? tag}) {
    if (!_enabled) return;
    debugPrint('${_prefix('D', tag)}$message');
  }

  static void i(String message, {String? tag}) {
    if (!_enabled) return;
    debugPrint('${_prefix('I', tag)}$message');
  }

  static void w(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;
    debugPrint('${_prefix('W', tag)}$message');
    if (error != null) debugPrint('   error: $error');
    if (stackTrace != null) debugPrint('   stack: $stackTrace');
  }

  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;
    debugPrint('${_prefix('E', tag)}$message');
    if (error != null) debugPrint('   error: $error');
    if (stackTrace != null) debugPrint('   stack: $stackTrace');
  }

  static String _prefix(String level, String? tag) =>
      tag == null ? '[$level] ' : '[$level][$tag] ';
}
