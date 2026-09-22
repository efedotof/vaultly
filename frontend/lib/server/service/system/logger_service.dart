import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as log_lib;
import 'package:shared_preferences/shared_preferences.dart';

enum LogLevel { trace, debug, info, warning, error, fatal, off }

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  late log_lib.Logger _logger;
  LogLevel _minLogLevel = LogLevel.debug;
  bool _enableFileLogging = false;
  final List<String> _logBuffer = [];
  static const int _maxBufferSize = 100;

  Future<void> init({
    LogLevel? minLogLevel,
    bool enableFileLogging = false,
  }) async {
    _enableFileLogging = enableFileLogging;

    _minLogLevel =
        minLogLevel ?? (kReleaseMode ? LogLevel.error : LogLevel.debug);

    final printer = kReleaseMode
        ? log_lib.SimplePrinter(colors: false)
        : log_lib.PrettyPrinter(
            methodCount: 2,
            errorMethodCount: 5,
            lineLength: 80,
            colors: true,
            printEmojis: true,
          );

    _logger = log_lib.Logger(
      printer: printer,
      level: _convertToLoggerLevel(_minLogLevel),
      output: _MultiOutput([
        _ConsoleOutput(),
        if (_enableFileLogging) _FileOutput(),
      ]),
    );

    await _loadSettings();

    if (kReleaseMode) {
      info('App started in release mode');
    }
  }

  void setLogLevel(LogLevel level) {
    _minLogLevel = level;
    log_lib.Logger.level = _convertToLoggerLevel(level);
    _saveSettings();
  }

  LogLevel get currentLevel => _minLogLevel;

  List<String> getLogBuffer() => List.unmodifiable(_logBuffer);

  void clearBuffer() => _logBuffer.clear();

  void trace(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (_minLogLevel.index <= LogLevel.trace.index) {
      _log('TRACE', message, error, stackTrace, tag);
    }
  }

  void debug(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (_minLogLevel.index <= LogLevel.debug.index) {
      _log('DEBUG', message, error, stackTrace, tag);
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  void info(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (_minLogLevel.index <= LogLevel.info.index) {
      _log('INFO', message, error, stackTrace, tag);
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  void warning(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (_minLogLevel.index <= LogLevel.warning.index) {
      _log('WARNING', message, error, stackTrace, tag);
      _logger.w(message, error: error, stackTrace: stackTrace);
    }
  }

  void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (_minLogLevel.index <= LogLevel.error.index) {
      _log('ERROR', message, error, stackTrace, tag);
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }

  void fatal(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (_minLogLevel.index <= LogLevel.fatal.index) {
      _log('FATAL', message, error, stackTrace, tag);
      _logger.f(message, error: error, stackTrace: stackTrace);
    }
  }

  void network(
    String method,
    String url, {
    dynamic request,
    dynamic response,
    int? statusCode,
    int? durationMs,
    String? tag,
  }) {
    if (_minLogLevel.index <= LogLevel.debug.index) {
      final logMessage =
          '[$method] $url '
          '${statusCode != null ? '($statusCode)' : ''} '
          '${durationMs != null ? '${durationMs}ms' : ''}';

      _log('NETWORK', logMessage, null, null, tag);

      if (kDebugMode) {
        if (request != null) {
          _log('NETWORK', 'Request: ${_formatJson(request)}', null, null, tag);
        }
        if (response != null) {
          _log(
            'NETWORK',
            'Response: ${_formatJson(response)}',
            null,
            null,
            tag,
          );
        }
      }
    }
  }

  void performance(
    String operation,
    int durationMs, {
    Map<String, dynamic>? extra,
    String? tag,
  }) {
    if (_minLogLevel.index <= LogLevel.info.index) {
      final message = '$operation completed in ${durationMs}ms';
      _log('PERFORMANCE', message, null, null, tag);
    }
  }

  void _log(
    String level,
    String message,
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag] ' : '';
    final errorStr = error != null ? ' | Error: $error' : '';
    final stackStr = stackTrace != null ? '\n$stackTrace' : '';

    final logEntry = '$timestamp [$level] $tagStr$message$errorStr$stackStr';

    _addToBuffer(logEntry);

    if (kDebugMode) {
      developer.log(
        message,
        name: 'AppLogger',
        level: _getDeveloperLevel(level),
        error: error,
        stackTrace: stackTrace,
        time: DateTime.now(),
      );
    } else if (!kReleaseMode) {}
  }

  void _addToBuffer(String logEntry) {
    _logBuffer.add(logEntry);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
  }

  String _formatJson(dynamic data) {
    try {
      if (data is String) {
        return data;
      }
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      return data.toString();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLevel = prefs.getInt('log_level');
      if (savedLevel != null) {
        _minLogLevel = LogLevel.values[savedLevel];
      }
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('log_level', _minLogLevel.index);
    } catch (_) {}
  }

  log_lib.Level _convertToLoggerLevel(LogLevel level) {
    switch (level) {
      case LogLevel.trace:
        return log_lib.Level.trace;
      case LogLevel.debug:
        return log_lib.Level.debug;
      case LogLevel.info:
        return log_lib.Level.info;
      case LogLevel.warning:
        return log_lib.Level.warning;
      case LogLevel.error:
        return log_lib.Level.error;
      case LogLevel.fatal:
        return log_lib.Level.fatal;
      case LogLevel.off:
        return log_lib.Level.off;
    }
  }

  int _getDeveloperLevel(String level) {
    switch (level) {
      case 'TRACE':
        return 0;
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARNING':
        return 900;
      case 'ERROR':
        return 1000;
      case 'FATAL':
        return 1200;
      default:
        return 500;
    }
  }
}

class _ConsoleOutput extends log_lib.LogOutput {
  @override
  void output(log_lib.OutputEvent event) {
    if (kReleaseMode && !kDebugMode) return;
  }
}

class _FileOutput extends log_lib.LogOutput {
  @override
  void output(log_lib.OutputEvent event) {}
}

class _MultiOutput extends log_lib.LogOutput {
  final List<log_lib.LogOutput> outputs;

  _MultiOutput(this.outputs);

  @override
  void output(log_lib.OutputEvent event) {
    for (final output in outputs) {
      output.output(event);
    }
  }
}
