import 'dart:async';
import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

part 'batch_cache_state.dart';
part 'batch_cache_cubit.freezed.dart';

class BatchCacheCubit extends Cubit<BatchCacheState> {
  final FileInterface fileRepository;
  final dynamic keyManagerService;
  final LocalFileCache localFileCache;
  final AuthCubit authCubit;
  final LoggerService _logger = LoggerService();

  BatchCacheCubit({
    required this.fileRepository,
    required this.keyManagerService,
    required this.localFileCache,
    required this.authCubit,
  }) : super(const BatchCacheState.initial());

  Future<void> cacheAllFiles(List<FileDto> files, {String? password}) async {
    if (files.isEmpty) {
      emit(const BatchCacheState.completed(cachedCount: 0, total: 0));
      return;
    }

    final pwd = password ?? authCubit.currentPassword;
    if (pwd == null || pwd.isEmpty) {
      emit(const BatchCacheState.error('Пароль не указан'));
      return;
    }

    emit(BatchCacheState.inProgress(current: 0, total: files.length));

    int cached = 0;
    int failed = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        await _cacheSingleFile(file, pwd);
        cached++;
      } catch (e, stack) {
        failed++;
        _logger.error(
          '[BatchCacheCubit] Ошибка кэширования файла ${file.id}',
          error: e,
          stackTrace: stack,
        );
      }
      await Future.delayed(Duration.zero);
      emit(BatchCacheState.inProgress(current: i + 1, total: files.length));
    }

    if (failed > 0) {
      emit(
        BatchCacheState.error(
          'Кэшировано $cached из ${files.length} файлов. Ошибок: $failed',
        ),
      );
    } else {
      emit(BatchCacheState.completed(cachedCount: cached, total: files.length));
    }
  }

  Future<void> _cacheSingleFile(FileDto file, String password) async {
    if (await localFileCache.hasFile(file.id!)) {
      return;
    }

    if (file.isPublic == true) {
      await _cachePublicFile(file, password);
    } else {
      await _cachePrivateFile(file, password);
    }
  }

  Future<void> _cachePublicFile(FileDto file, String password) async {
    final metadata = await fileRepository.getDecryptionMetadata(file.id!);

    dynamic clientPrivateKey;
    if (kIsWeb) {
      clientPrivateKey = await keyManagerService.getPrivateKeyPEM(password);
    } else {
      clientPrivateKey = await keyManagerService.getPrivateKey(password);
    }
    if (clientPrivateKey == null) {
      throw Exception('Не удалось получить приватный ключ');
    }

    final String clientPrivateKeyPem;
    if (kIsWeb) {
      clientPrivateKeyPem = clientPrivateKey as String;
    } else {
      clientPrivateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(
        clientPrivateKey,
      );
    }

    if (kIsWeb) {
      final shpsData = await fileRepository.downloadShpsFromUrl(
        metadata.presignedUrl,
      );
      final decrypted = await PublicFileDecryptionService.decryptPublicFile(
        shpsData: shpsData,
        reEncryptedKeyBase64: metadata.encryptedKey,
        ivBase64: metadata.iv,
        clientPrivateKeyPem: clientPrivateKeyPem,
      );
      await localFileCache.saveFile(
        file.id!,
        decrypted,
        originalName: metadata.fileName,
      );
    } else {
      final shpsData = await fileRepository.downloadShpsFromUrl(
        metadata.presignedUrl,
      );
      final decrypted = await PublicFileDecryptionService.decryptPublicFile(
        shpsData: shpsData,
        reEncryptedKeyBase64: metadata.encryptedKey,
        ivBase64: metadata.iv,
        clientPrivateKeyPem: clientPrivateKeyPem,
      );
      await localFileCache.saveFile(
        file.id!,
        decrypted,
        originalName: metadata.fileName,
      );
    }
  }

  Future<void> _cachePrivateFile(FileDto file, String password) async {
    if (kIsWeb) {
      final encryptedStream = await fileRepository.downloadShpsStream(file.id!);
      final header = await _extractHeaderFromStream(encryptedStream);
      final keyOwner = header.keyOwner;

      String? privateKeyPem;
      if (keyOwner == 'device') {
        privateKeyPem = await keyManagerService.getDevicePrivateKeyPEM(
          password,
        );
      } else {
        privateKeyPem = await keyManagerService.getPrivateKeyPEM(password);
      }
      if (privateKeyPem == null) throw Exception('Приватный ключ не получен');

      final decryptedStream = ShirmDecryptionService.decryptShpsChunked(
        encryptedDataStream: encryptedStream,
        readHeaderFromStream: true,
        privateKeyPem: privateKeyPem,
      );
      await localFileCache.saveFileChunked(
        file.id!,
        decryptedStream,
        originalName: header.originalFileName ?? file.originalName,
      );
    } else {
      final encryptedBytes = await fileRepository.downloadShps(file.id!);
      final header = _extractShirmpsHeader(encryptedBytes);
      final keyOwner = header.keyOwner;

      String? privateKeyPem;
      if (keyOwner == 'device') {
        final deviceKey = await keyManagerService.getDevicePrivateKeyObject(
          password,
        );
        if (deviceKey != null) {
          privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(deviceKey);
        }
      } else {
        final userKey = await keyManagerService.getPrivateKey(password);
        if (userKey != null) {
          privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(userKey);
        }
      }
      if (privateKeyPem == null) throw Exception('Приватный ключ не получен');

      final decrypted = await ShirmDecryptionService.decryptShps(
        encryptedBytes,
        privateKeyPem: privateKeyPem,
      );
      await localFileCache.saveFile(
        file.id!,
        decrypted,
        originalName: header.originalFileName ?? file.originalName,
      );
    }
  }

  Future<ShirmpsHeader> _extractHeaderFromStream(
    Stream<Uint8List> stream,
  ) async {
    final headerLenBuffer = await _readExactly(stream, 4);
    final headerLength = ByteData.view(
      headerLenBuffer.buffer,
    ).getInt32(0, Endian.big);
    final headerBytes = await _readExactly(stream, headerLength);
    return ShirmpsHeader.fromJsonBytes(headerBytes);
  }

  Future<Uint8List> _readExactly(Stream<Uint8List> stream, int length) async {
    final completer = Completer<Uint8List>();
    List<int> buffer = [];
    int received = 0;
    StreamSubscription<Uint8List>? subscription;
    subscription = stream.listen(
      (data) {
        buffer.addAll(data);
        received += data.length;
        if (received >= length) {
          subscription?.cancel();
          completer.complete(Uint8List.fromList(buffer.sublist(0, length)));
        }
      },
      onError: (err) {
        if (!completer.isCompleted) completer.completeError(err);
      },
      onDone: () {
        if (!completer.isCompleted && received < length) {
          completer.completeError(
            Exception('Stream ended before reading $length bytes'),
          );
        }
      },
    );
    return completer.future;
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
}
