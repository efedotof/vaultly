import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:vaulth_app/features/auth/cubit/auth_cubit.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';
import 'package:vaulth_app/server/service/cache/local_file_cache_platform.dart';
import 'package:vaulth_app/server/service/system/logger_service.dart';
import 'package:vaulth_app/server/service/decryption/public_file_decryption_service.dart';
import 'package:vaulth_app/server/service/decryption/shirm_decryption_service_platform.dart';
import 'package:vaulth_app/server/service/system/shirmps_header.dart';

import 'file_saver.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

part 'document_viewer_state.dart';
part 'document_viewer_cubit.freezed.dart';

class _DecryptParams {
  final Uint8List encryptedBytes;
  final String privateKeyPem;
  final bool compressed;
  _DecryptParams({
    required this.encryptedBytes,
    required this.privateKeyPem,
    required this.compressed,
  });
}

Future<Uint8List> _decryptAndDecompressInIsolate(_DecryptParams params) async {
  final decrypted = await ShirmDecryptionService.decryptShps(
    params.encryptedBytes,
    privateKeyPem: params.privateKeyPem,
  );

  if (!params.compressed) {
    return decrypted;
  }

  final gzip = GZipDecoder();
  return Uint8List.fromList(gzip.decodeBytes(decrypted));
}

class DocumentViewerCubit extends Cubit<DocumentViewerState> {
  final FileInterface fileRepository;
  final dynamic keyManagerService;
  final LocalFileCache localFileCache;
  final LoggerService _logger = LoggerService();
  final AuthCubit authCubit;

  String? _currentlyLoadingFileId;
  FileDto? _lastFile;
  String? _lastPassword;

  DocumentViewerCubit({
    required this.fileRepository,
    required this.keyManagerService,
    required this.localFileCache,
    required this.authCubit,
  }) : super(const DocumentViewerState.initial());

  Future<void> loadFile({
    required FileDto file,
    required String password,
  }) async {
    if (_currentlyLoadingFileId == file.id) {
      return;
    }
    _currentlyLoadingFileId = file.id;
    _lastFile = file;
    _lastPassword = password;

    emit(const DocumentViewerState.loading());

    try {
      final cachedData = await localFileCache.getFileDecrypted(file.id!);
      if (cachedData != null) {
        String? cachedOriginalName = await localFileCache.getOriginalName(
          file.id!,
        );
        final displayName = cachedOriginalName ?? file.originalName;
        final contentType = _detectContentType(cachedData, displayName);
        emit(
          DocumentViewerState.loaded(
            data: cachedData,
            fileName: displayName,
            contentType: contentType,
          ),
        );
        return;
      }

      if (file.isPublic == true) {
        await _loadPublicFile(file);
      } else {
        await _loadPrivateFile(file, password);
      }
    } catch (e, stackTrace) {
      _logger.error(
        '[DocumentViewerCubit] Ошибка',
        error: e,
        stackTrace: stackTrace,
      );
      emit(DocumentViewerState.error(_formatErrorMessage(e)));
    } finally {
      _currentlyLoadingFileId = null;
    }
  }

  Future<void> retry() async {
    if (_lastFile == null) return;

    await Future.delayed(const Duration(milliseconds: 300));
    await loadFile(file: _lastFile!, password: _lastPassword ?? '');
  }

  Future<void> _loadPublicFile(FileDto file) async {
    if (authCubit.currentPassword == "") {
      return;
    }
    String password = authCubit.currentPassword!;
    final metadata = await fileRepository.getDecryptionMetadata(file.id!);

    emit(const DocumentViewerState.downloading());

    final shpsData = await fileRepository.downloadShpsFromUrl(
      metadata.presignedUrl,
    );

    dynamic clientPrivateKey;
    if (kIsWeb) {
      clientPrivateKey = await keyManagerService.getPrivateKeyPEM(password);
    } else {
      clientPrivateKey = await keyManagerService.getPrivateKey(password);
    }

    if (clientPrivateKey == null) {
      emit(
        const DocumentViewerState.error('Неверный пароль или ключ не найден'),
      );
      return;
    }

    final String clientPrivateKeyPem;
    if (kIsWeb) {
      clientPrivateKeyPem = clientPrivateKey as String;
    } else {
      clientPrivateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(
        clientPrivateKey,
      );
    }

    emit(const DocumentViewerState.decrypting());
    try {
      _validateBase64(metadata.encryptedKey, 'encryptedKey');
      _validateBase64(metadata.iv, 'iv');

      final decryptedBytes =
          await PublicFileDecryptionService.decryptPublicFile(
            shpsData: shpsData,
            reEncryptedKeyBase64: metadata.encryptedKey,
            ivBase64: metadata.iv,
            clientPrivateKeyPem: clientPrivateKeyPem,
          );

      await localFileCache.saveFile(
        file.id!,
        decryptedBytes,
        originalName: metadata.fileName,
      );

      final contentType = _detectContentType(decryptedBytes, metadata.fileName);
      emit(
        DocumentViewerState.loaded(
          data: decryptedBytes,
          fileName: metadata.fileName,
          contentType: contentType,
        ),
      );
    } catch (e, stack) {
      _logger.error(
        '[DocumentViewerCubit] Ошибка в PublicFileDecryptionService',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> _loadPrivateFile(FileDto file, String password) async {
    final encryptedBytes = await fileRepository.downloadShps(file.id!);

    String originalFileName = file.originalName;
    String? keyOwner;
    bool compressed = false;
    try {
      final header = _extractShirmpsHeader(encryptedBytes);
      if (header.originalFileName != null &&
          header.originalFileName!.isNotEmpty) {
        originalFileName = header.originalFileName!;
      }
      keyOwner = header.keyOwner;
      compressed = header.compressed;
    } catch (_) {}

    final keys = await _getAvailablePrivateKeys(password);

    final List<String> pemKeysToTry = [];
    if (keyOwner == 'device') {
      if (keys.deviceKey != null) pemKeysToTry.add(keys.deviceKey!);
      if (keys.userKey != null) pemKeysToTry.add(keys.userKey!);
    } else {
      if (keys.userKey != null) pemKeysToTry.add(keys.userKey!);
      if (keys.deviceKey != null) pemKeysToTry.add(keys.deviceKey!);
    }

    if (pemKeysToTry.isEmpty) {
      emit(
        const DocumentViewerState.error('Неверный пароль или ключ не найден'),
      );
      return;
    }

    emit(const DocumentViewerState.decrypting());

    Exception? lastError;
    for (int i = 0; i < pemKeysToTry.length; i++) {
      final pem = pemKeysToTry[i];

      try {
        Uint8List decryptedBytes = await _decryptShpsWithPem(
          encryptedBytes: encryptedBytes,
          privateKeyPem: pem,
          compressed: compressed,
        );

        localFileCache.saveFileInBackground(
          fileId: file.id!,
          data: decryptedBytes,
          originalName: originalFileName,
        );

        final contentType = _detectContentType(
          decryptedBytes,
          originalFileName,
        );
        emit(
          DocumentViewerState.loaded(
            data: decryptedBytes,
            fileName: originalFileName,
            contentType: contentType,
          ),
        );
        return;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    _logger.error(
      '[DocumentViewerCubit] Ошибка расшифровки приватного файла',
      error: lastError,
    );

    emit(DocumentViewerState.error(_formatErrorMessage(lastError)));
  }

  Future<({String? userKey, String? deviceKey})> _getAvailablePrivateKeys(
    String password,
  ) async {
    String? userPem;
    String? devicePem;

    if (kIsWeb) {
      userPem = await keyManagerService.getPrivateKeyPEM(password);
      devicePem = await keyManagerService.getDevicePrivateKeyPEM(password);
    } else {
      final userKey = await keyManagerService.getPrivateKey(password);
      if (userKey != null) {
        userPem = CryptoUtils.encodeRSAPrivateKeyToPem(userKey);
      }
      final deviceKey = await keyManagerService.getDevicePrivateKeyObject(
        password,
      );
      if (deviceKey != null) {
        devicePem = CryptoUtils.encodeRSAPrivateKeyToPem(deviceKey);
      }
    }
    return (userKey: userPem, deviceKey: devicePem);
  }

  Future<Uint8List> _decryptShpsWithPem({
    required Uint8List encryptedBytes,
    required String privateKeyPem,
    required bool compressed,
  }) async {
    if (kIsWeb) {
      final result = await ShirmDecryptionService.decryptShps(
        encryptedBytes,
        privateKeyPem: privateKeyPem,
      );
      return result;
    } else {
      return await compute(
        _decryptAndDecompressInIsolate,
        _DecryptParams(
          encryptedBytes: encryptedBytes,
          privateKeyPem: privateKeyPem,
          compressed: compressed,
        ),
      );
    }
  }

  ShirmpsHeader _extractShirmpsHeader(Uint8List shpsBytes) {
    try {
      final byteData = shpsBytes.buffer.asByteData(
        shpsBytes.offsetInBytes,
        shpsBytes.length,
      );
      final headerLength = byteData.getInt32(0, Endian.big);

      if (headerLength <= 0 || headerLength > 20 * 1024) {
        throw Exception('Invalid header length: $headerLength');
      }
      final headerBytes = shpsBytes.sublist(4, 4 + headerLength);
      return ShirmpsHeader.fromJsonBytes(headerBytes);
    } catch (e) {
      rethrow;
    }
  }

  void _validateBase64(String base64Str, String fieldName) {
    try {
      base64Decode(base64Str);
    } catch (e) {
      throw FormatException('Invalid Base64 for $fieldName: $e');
    }
  }

  String _formatErrorMessage(dynamic error) {
    if (error is Exception) {
      final msg = error.toString();
      if (msg.contains('DioException') || msg.contains('SocketException')) {
        return 'Ошибка сети. Проверьте подключение к интернету.';
      }
      if (msg.contains('Invalid header length') ||
          msg.contains('Unsupported SHPS version')) {
        return 'Файл повреждён или имеет неверный формат.';
      }
      if (msg.contains('RSA') || msg.contains('decrypt')) {
        return 'Ошибка расшифровки. Возможно, неверный пароль или ключ.';
      }
      return 'Ошибка: $msg';
    }
    return 'Неизвестная ошибка: $error';
  }

  ContentType _detectContentType(Uint8List data, String fileName) {
    final lowerName = fileName.toLowerCase();
    const codeExtensions = [
      '.dart',
      '.java',
      '.kt',
      '.kts',
      '.swift',
      '.c',
      '.cpp',
      '.cc',
      '.cxx',
      '.h',
      '.hpp',
      '.py',
      '.pyw',
      '.js',
      '.mjs',
      '.ts',
      '.jsx',
      '.tsx',
      '.html',
      '.htm',
      '.css',
      '.scss',
      '.sass',
      '.less',
      '.json',
      '.xml',
      '.yaml',
      '.yml',
      '.toml',
      '.sh',
      '.bat',
      '.ps1',
      '.go',
      '.rs',
      '.rb',
      '.php',
      '.sql',
      '.r',
      '.m',
      '.mm',
      '.vue',
      '.svelte',
      '.gradle',
      '.properties',
      '.env',
      '.gitignore',
      '.dockerignore',
    ];
    for (final ext in codeExtensions) {
      if (lowerName.endsWith(ext)) return ContentType.code;
    }
    if (lowerName.endsWith('.md') || lowerName.endsWith('.markdown')) {
      return ContentType.markdown;
    }
    if (lowerName.endsWith('.txt') ||
        lowerName.endsWith('.json') ||
        lowerName.endsWith('.xml') ||
        lowerName.endsWith('.csv') ||
        lowerName.endsWith('.log')) {
      return ContentType.text;
    }
    if (lowerName.endsWith('.pdf')) return ContentType.pdf;
    if (lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.avi') ||
        lowerName.endsWith('.mkv') ||
        lowerName.endsWith('.webm') ||
        lowerName.endsWith('.m4v') ||
        lowerName.endsWith('.3gp')) {
      return ContentType.video;
    }
    if (lowerName.endsWith('.doc') ||
        lowerName.endsWith('.docx') ||
        lowerName.endsWith('.xls') ||
        lowerName.endsWith('.xlsx') ||
        lowerName.endsWith('.ppt') ||
        lowerName.endsWith('.pptx') ||
        lowerName.endsWith('.odt') ||
        lowerName.endsWith('.ods')) {
      return ContentType.office;
    }
    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.bmp') ||
        lowerName.endsWith('.webp') ||
        lowerName.endsWith('.heic')) {
      return ContentType.image;
    }

    if (data.length > 4) {
      if (data[0] == 0xFF && data[1] == 0xD8) return ContentType.image;
      if (data[0] == 0x89 &&
          data[1] == 0x50 &&
          data[2] == 0x4E &&
          data[3] == 0x47) {
        return ContentType.image;
      }
      if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46) {
        return ContentType.image;
      }
      if (data[0] == 0x25 &&
          data[1] == 0x50 &&
          data[2] == 0x44 &&
          data[3] == 0x46) {
        return ContentType.pdf;
      }
      if (data.length > 8 &&
          data[4] == 0x66 &&
          data[5] == 0x74 &&
          data[6] == 0x79 &&
          data[7] == 0x70) {
        return ContentType.video;
      }
    }

    return ContentType.binary;
  }

  Future<void> downloadFile() async {
    final currentState = state;
    if (currentState is! _Loaded) {
      _logger.debug(
        '[DocumentViewerCubit] downloadFile вызван, но файл не загружен',
      );
      return;
    }

    if (kIsWeb) {
      try {
        await saveFileWeb(currentState.data, currentState.fileName);
        _logger.info(
          '[DocumentViewerCubit] Файл сохранён (Web): ${currentState.fileName}',
        );
      } catch (e, stackTrace) {
        _logger.error(
          '[DocumentViewerCubit] Ошибка сохранения в Web',
          error: e,
          stackTrace: stackTrace,
        );
        rethrow;
      }
      return;
    }

    try {
      if (io.Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Нет разрешения на запись в хранилище');
        }
      }

      io.Directory downloadsDir;
      if (io.Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir == null) {
          throw Exception('Не удалось получить доступ к внешнему хранилищу');
        }
        final rootPath = extDir.parent.parent.path;
        downloadsDir = io.Directory('$rootPath/Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
      } else {
        final dir = await getDownloadsDirectory();
        if (dir == null) throw Exception('Не удалось получить папку Downloads');
        downloadsDir = dir;
      }

      String fileName = currentState.fileName;
      String filePath = '${downloadsDir.path}/$fileName';
      final file = io.File(filePath);

      if (await file.exists()) {
        final ext = fileName.contains('.')
            ? fileName.substring(fileName.lastIndexOf('.'))
            : '';
        final base = fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        fileName = '${base}_$timestamp$ext';
        filePath = '${downloadsDir.path}/$fileName';
      }

      await io.File(filePath).writeAsBytes(currentState.data);
      _logger.info('[DocumentViewerCubit] Файл сохранён в $filePath');
    } catch (e, stackTrace) {
      _logger.error(
        '[DocumentViewerCubit] Ошибка сохранения',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
