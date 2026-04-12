import 'package:flutter/foundation.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';
import 'package:vaulth_app/server/service/local_file_cache.dart';
import 'package:vaulth_app/server/service/logger_service.dart';
import 'package:vaulth_app/server/service/public_file_decryption_service.dart';
import 'package:vaulth_app/server/service/shirm_decryption_service.dart';
import 'package:vaulth_app/server/service/shirm_decryption_service_web.dart';
import 'package:vaulth_app/server/service/shirmps_header.dart';

class FileDecryptionService {
  final FileInterface fileRepository;
  final dynamic keyManagerService;
  final LocalFileCache localFileCache;
  final LoggerService _logger = LoggerService();

  FileDecryptionService({
    required this.fileRepository,
    required this.keyManagerService,
    required this.localFileCache,
  });

  Future<Uint8List> decryptAndCache({
    required FileDto file,
    required String password,
  }) async {
    final cached = await localFileCache.getFile(file.id!);
    if (cached != null) {
      _logger.debug('[FileDecryptionService] Файл ${file.id} уже в кэше');
      return cached;
    }

    if (file.isPublic == true) {
      return await _decryptPublicFile(file, password);
    } else {
      return await _decryptPrivateFile(file, password);
    }
  }

  Future<Uint8List> _decryptPublicFile(FileDto file, String password) async {
    _logger.debug(
      '[FileDecryptionService] Расшифровка публичного файла ${file.id}',
    );

    final metadata = await fileRepository.getDecryptionMetadata(file.id!);

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
      throw Exception('Не удалось получить приватный ключ. Неверный пароль?');
    }

    final decryptedBytes = await PublicFileDecryptionService.decryptPublicFile(
      shpsData: shpsData,
      reEncryptedKeyBase64: metadata.encryptedKey,
      ivBase64: metadata.iv,
      clientPrivateKey: clientPrivateKey,
    );

    await localFileCache.saveFile(
      file.id!,
      decryptedBytes,
      originalName: metadata.fileName,
    );

    return decryptedBytes;
  }

  Future<Uint8List> _decryptPrivateFile(FileDto file, String password) async {
    _logger.debug(
      '[FileDecryptionService] Расшифровка приватного файла ${file.id}',
    );

    final encryptedBytes = await fileRepository.downloadShps(file.id!);

    String originalFileName = file.originalName;
    try {
      final header = _extractShirmpsHeader(encryptedBytes);
      if (header.originalFileName != null &&
          header.originalFileName!.isNotEmpty) {
        originalFileName = header.originalFileName!;
      }
    } catch (e) {
      _logger.error(
        '[FileDecryptionService] Ошибка извлечения заголовка',
        error: e,
      );
    }

    String? privateKeyPem;
    if (kIsWeb) {
      privateKeyPem = await keyManagerService.getPrivateKeyPEM(password);
    } else {
      final privateKey = await keyManagerService.getPrivateKey(password);
      if (privateKey == null) {
        throw Exception('Не удалось получить приватный ключ. Неверный пароль?');
      }
      privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);
    }

    if (privateKeyPem == null || privateKeyPem.isEmpty) {
      throw Exception('Приватный ключ не получен');
    }

    Uint8List decryptedBytes;
    if (kIsWeb) {
      decryptedBytes = await ShirmDecryptionServiceWeb.decryptShps(
        encryptedBytes,
        privateKeyPem: privateKeyPem,
      );
    } else {
      decryptedBytes = ShirmDecryptionService.decryptShps(
        encryptedBytes,
        privateKey: CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem),
      );
    }

    await localFileCache.saveFile(
      file.id!,
      decryptedBytes,
      originalName: originalFileName,
    );

    return decryptedBytes;
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
