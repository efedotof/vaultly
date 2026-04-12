import 'dart:io';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:vaulth_app/features/auth/cubit/auth_cubit.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';
import 'package:vaulth_app/server/service/local_file_cache.dart';
import 'package:vaulth_app/server/service/logger_service.dart';
import 'package:vaulth_app/server/service/public_file_decryption_service.dart';
import 'package:vaulth_app/server/service/shirm_decryption_service.dart';
import 'package:vaulth_app/server/service/shirm_decryption_service_web.dart';
import 'package:vaulth_app/server/service/shirmps_header.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform, Directory, File;
import 'dart:io';
part 'document_viewer_state.dart';
part 'document_viewer_cubit.freezed.dart';

class _DecryptParams {
  final String inputPath;
  final String outputPath;
  final String privateKeyPem;
  _DecryptParams({
    required this.inputPath,
    required this.outputPath,
    required this.privateKeyPem,
  });
}

Future<void> _decryptShpsInIsolate(_DecryptParams params) async {
  final inputFile = File(params.inputPath);
  final outputFile = File(params.outputPath);
  final encryptedBytes = await inputFile.readAsBytes();
  final privateKey = CryptoUtils.rsaPrivateKeyFromPem(params.privateKeyPem);
  final decryptedBytes = ShirmDecryptionService.decryptShps(
    encryptedBytes,
    privateKey: privateKey,
  );
  await outputFile.writeAsBytes(decryptedBytes);
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
      _logger.debug(
        '[DocumentViewerCubit] Already loading file ${file.id}, skipping duplicate call',
      );
      return;
    }
    _currentlyLoadingFileId = file.id;
    _lastFile = file;
    _lastPassword = password;

    _logger.info(
      '[DocumentViewerCubit] Начало загрузки файла: ${file.originalName} (id: ${file.id})',
    );
    emit(const DocumentViewerState.loading());

    try {
      final cachedData = await localFileCache.getFile(file.id!);
      if (cachedData != null) {
        _logger.info('[DocumentViewerCubit] Файл найден в кэше');
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
        return;
      }

      await _loadPrivateFile(file, password);
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
    if (authCubit.currentPassword == "") return;
    String password = authCubit.currentPassword!;

    _logger.debug(
      '[DocumentViewerCubit] Публичный файл, получение метаданных...',
    );

    final metadata = await fileRepository.getDecryptionMetadata(file.id!);
    _logger.debug(
      '[DocumentViewerCubit] Метаданные получены, presigned URL: ${metadata.presignedUrl}',
    );

    emit(const DocumentViewerState.downloading());
    final shpsData = await fileRepository.downloadShpsFromUrl(
      metadata.presignedUrl,
    );
    _logger.debug(
      '[DocumentViewerCubit] SHPS файл скачан, размер: ${shpsData.length} байт',
    );

    dynamic clientPrivateKey;
    if (kIsWeb) {
      clientPrivateKey = await keyManagerService.getPrivateKeyPEM(password);
    } else {
      clientPrivateKey = await keyManagerService.getPrivateKey(password);
    }

    if (clientPrivateKey == null) {
      _logger.error(
        '[DocumentViewerCubit] Не удалось получить приватный ключ клиента',
      );
      emit(
        const DocumentViewerState.error('Неверный пароль или ключ не найден'),
      );
      return;
    }

    emit(const DocumentViewerState.decrypting());
    final decryptedBytes = await PublicFileDecryptionService.decryptPublicFile(
      shpsData: shpsData,
      reEncryptedKeyBase64: metadata.encryptedKey,
      ivBase64: metadata.iv,
      clientPrivateKey: clientPrivateKey,
    );
    _logger.debug(
      '[DocumentViewerCubit] Расшифровка завершена, размер: ${decryptedBytes.length} байт',
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
  }

  Future<void> _loadPrivateFile(FileDto file, String password) async {
    _logger.debug('[DocumentViewerCubit] Приватный файл, загрузка SHPS...');
    final encryptedBytes = await fileRepository.downloadShps(file.id!);
    _logger.debug(
      '[DocumentViewerCubit] Файл получен, размер: ${encryptedBytes.length} байт',
    );

    String originalFileName = file.originalName;
    try {
      final header = _extractShirmpsHeader(encryptedBytes);
      if (header.originalFileName != null &&
          header.originalFileName!.isNotEmpty) {
        originalFileName = header.originalFileName!;
        _logger.debug(
          '[DocumentViewerCubit] Оригинальное имя из заголовка: $originalFileName',
        );
      }
    } catch (e) {
      _logger.error(
        '[DocumentViewerCubit] Ошибка извлечения заголовка SHPS',
        error: e,
      );
    }

    String? privateKeyPem;
    if (kIsWeb) {
      privateKeyPem = await keyManagerService.getPrivateKeyPEM(password);
    } else {
      final privateKey = await keyManagerService.getPrivateKey(password);
      if (privateKey == null) {
        _logger.error(
          '[DocumentViewerCubit] Не удалось получить приватный ключ',
        );
        emit(
          const DocumentViewerState.error('Неверный пароль или ключ не найден'),
        );
        return;
      }
      privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);
    }

    if (privateKeyPem == null || privateKeyPem.isEmpty) {
      _logger.error('[DocumentViewerCubit] Приватный ключ не получен');
      emit(
        const DocumentViewerState.error('Неверный пароль или ключ не найден'),
      );
      return;
    }

    emit(const DocumentViewerState.decrypting());

    Uint8List decryptedBytes;
    if (kIsWeb) {
      decryptedBytes = await ShirmDecryptionServiceWeb.decryptShps(
        encryptedBytes,
        privateKeyPem: privateKeyPem,
      );
    } else {
      String? tempEncryptedPath;
      String? tempDecryptedPath;
      try {
        final tempDir = await getTemporaryDirectory();
        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
          _logger.debug(
            '[DocumentViewerCubit] Создана временная директория: ${tempDir.path}',
          );
        }
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        tempEncryptedPath = '${tempDir.path}/enc_$timestamp.shps';
        tempDecryptedPath = '${tempDir.path}/dec_$timestamp.bin';

        await File(tempEncryptedPath).writeAsBytes(encryptedBytes);

        await compute(
          _decryptShpsInIsolate,
          _DecryptParams(
            inputPath: tempEncryptedPath,
            outputPath: tempDecryptedPath,
            privateKeyPem: privateKeyPem,
          ),
        );

        final decryptedFile = File(tempDecryptedPath);
        decryptedBytes = await decryptedFile.readAsBytes();
      } finally {
        await _deleteTempFiles([tempEncryptedPath, tempDecryptedPath]);
      }
    }

    _logger.debug(
      '[DocumentViewerCubit] Расшифровка завершена, размер: ${decryptedBytes.length} байт',
    );

    await localFileCache.saveFile(
      file.id!,
      decryptedBytes,
      originalName: originalFileName,
    );

    final contentType = _detectContentType(decryptedBytes, originalFileName);
    emit(
      DocumentViewerState.loaded(
        data: decryptedBytes,
        fileName: originalFileName,
        contentType: contentType,
      ),
    );
  }

  Future<void> _deleteTempFiles(List<String?> paths) async {
    for (final path in paths) {
      if (path != null) {
        try {
          final f = File(path);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
  }

  ShirmpsHeader _extractShirmpsHeader(Uint8List shpsBytes) {
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

    if (lowerName.endsWith('.txt') ||
        lowerName.endsWith('.json') ||
        lowerName.endsWith('.xml') ||
        lowerName.endsWith('.csv') ||
        lowerName.endsWith('.log') ||
        lowerName.endsWith('.md')) {
      return ContentType.text;
    }

    if (lowerName.endsWith('.pdf')) {
      return ContentType.pdf;
    }

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

    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Нет разрешения на запись в хранилище');
        }
      }

      Directory downloadsDir;
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir == null) {
          throw Exception('Не удалось получить доступ к внешнему хранилищу');
        }
        final rootPath = extDir.parent.parent.path;
        downloadsDir = Directory('$rootPath/Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
      } else {
        final dir = await getDownloadsDirectory();
        if (dir == null) {
          throw Exception('Не удалось получить папку Downloads');
        }
        downloadsDir = dir;
      }

      String fileName = currentState.fileName;
      String filePath = '${downloadsDir.path}/$fileName';
      final file = File(filePath);

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

      await File(filePath).writeAsBytes(currentState.data);
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
