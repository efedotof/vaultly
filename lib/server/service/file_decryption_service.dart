import 'dart:async';
import 'dart:math';
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
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';

Future<Map<String, dynamic>> _processPrivateFileInIsolate(
  Map<String, dynamic> args,
) async {
  final Uint8List encryptedBytes = args['encryptedBytes'] as Uint8List;
  final String privateKeyPem = args['privateKeyPem'] as String;

  final privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
  final Uint8List plaintext = ShirmDecryptionService.decryptShps(
    encryptedBytes,
    privateKey: privateKey,
  );

  final random = Random.secure();
  final key = Uint8List(32);
  final nonce = Uint8List(12);
  for (int i = 0; i < 32; i++) {
    key[i] = random.nextInt(256);
  }
  for (int i = 0; i < 12; i++) {
    nonce[i] = random.nextInt(256);
  }

  final keyParam = KeyParameter(key);
  final gcm = GCMBlockCipher(AESEngine())
    ..init(true, AEADParameters(keyParam, 128, nonce, Uint8List(0)));
  final ciphertext = Uint8List(gcm.getOutputSize(plaintext.length));
  final processed = gcm.processBytes(
    plaintext,
    0,
    plaintext.length,
    ciphertext,
    0,
  );
  final finalised = gcm.doFinal(ciphertext, processed);
  final total = processed + finalised;
  final encryptedData = Uint8List.sublistView(ciphertext, 0, total);

  return {'key': key, 'nonce': nonce, 'encryptedData': encryptedData};
}

Future<Map<String, dynamic>> _processPublicFileInIsolate(
  Map<String, dynamic> args,
) async {
  final Uint8List shpsData = args['shpsData'] as Uint8List;
  final String reEncryptedKeyBase64 = args['reEncryptedKeyBase64'] as String;
  final String ivBase64 = args['ivBase64'] as String;
  final String clientPrivateKeyPem = args['clientPrivateKeyPem'] as String;

  final clientPrivateKey = CryptoUtils.rsaPrivateKeyFromPem(
    clientPrivateKeyPem,
  );
  final Uint8List plaintext =
      await PublicFileDecryptionService.decryptPublicFile(
        shpsData: shpsData,
        reEncryptedKeyBase64: reEncryptedKeyBase64,
        ivBase64: ivBase64,
        clientPrivateKey: clientPrivateKey,
      );

  final random = Random.secure();
  final key = Uint8List(32);
  final nonce = Uint8List(12);
  for (int i = 0; i < 32; i++) {
    key[i] = random.nextInt(256);
  }
  for (int i = 0; i < 12; i++) {
    nonce[i] = random.nextInt(256);
  }

  final keyParam = KeyParameter(key);
  final gcm = GCMBlockCipher(AESEngine())
    ..init(true, AEADParameters(keyParam, 128, nonce, Uint8List(0)));
  final ciphertext = Uint8List(gcm.getOutputSize(plaintext.length));
  final processed = gcm.processBytes(
    plaintext,
    0,
    plaintext.length,
    ciphertext,
    0,
  );
  final finalised = gcm.doFinal(ciphertext, processed);
  final total = processed + finalised;
  final encryptedData = Uint8List.sublistView(ciphertext, 0, total);

  return {'key': key, 'nonce': nonce, 'encryptedData': encryptedData};
}

class FileDecryptionService {
  final FileInterface fileRepository;
  final dynamic keyManagerService;
  final LocalFileCache localFileCache;
  final LoggerService _logger = LoggerService();

  FileDecryptionService({
    required this.fileRepository,
    required this.keyManagerService,
    required this.localFileCache,
  }) {
    _logger.debug('[FileDecryptionService] Создан экземпляр сервиса');
  }

  Future<Uint8List> decryptAndCache({
    required FileDto file,
    required String password,
  }) async {
    _logger.debug(
      '[FileDecryptionService] decryptAndCache START для файла ${file.id}',
    );
    try {
      final cached = await localFileCache.getFileDecrypted(file.id!);
      if (cached != null) {
        _logger.debug('[FileDecryptionService] Файл ${file.id} уже в кэше');
        return cached;
      }

      _logger.debug(
        '[FileDecryptionService] Файл ${file.id} не найден в кэше, начинаем расшифровку',
      );
      if (file.isPublic == true) {
        return await _decryptPublicFile(file, password);
      } else {
        return await _decryptPrivateFile(file, password);
      }
    } catch (e, stackTrace) {
      _logger.error(
        '[FileDecryptionService] Ошибка в decryptAndCache для файла ${file.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
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

    final String clientPrivateKeyPem;
    if (kIsWeb) {
      clientPrivateKeyPem = clientPrivateKey as String;
    } else {
      clientPrivateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(
        clientPrivateKey,
      );
    }

    Uint8List plaintext;
    if (kIsWeb) {
      plaintext = await PublicFileDecryptionService.decryptPublicFile(
        shpsData: shpsData,
        reEncryptedKeyBase64: metadata.encryptedKey,
        ivBase64: metadata.iv,
        clientPrivateKey: clientPrivateKey,
      );
      await localFileCache.saveFile(
        file.id!,
        plaintext,
        originalName: metadata.fileName,
      );
    } else {
      final result = await compute(_processPublicFileInIsolate, {
        'shpsData': shpsData,
        'reEncryptedKeyBase64': metadata.encryptedKey,
        'ivBase64': metadata.iv,
        'clientPrivateKeyPem': clientPrivateKeyPem,
      });
      await localFileCache.saveFileEncrypted(
        fileId: file.id!,
        key: result['key'] as Uint8List,
        nonce: result['nonce'] as Uint8List,
        encryptedData: result['encryptedData'] as Uint8List,
        originalName: metadata.fileName,
      );
      plaintext = await _decryptFromCache(
        file.id!,
        result['key'] as Uint8List,
        result['nonce'] as Uint8List,
      );
    }

    return plaintext;
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
        '[FileDecryptionService] Ошибка извлечения заголовка для ${file.id}',
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

    Uint8List plaintext;
    if (kIsWeb) {
      plaintext = await ShirmDecryptionServiceWeb.decryptShps(
        encryptedBytes,
        privateKeyPem: privateKeyPem,
      );
      await localFileCache.saveFile(
        file.id!,
        plaintext,
        originalName: originalFileName,
      );
    } else {
      final result = await compute(_processPrivateFileInIsolate, {
        'encryptedBytes': encryptedBytes,
        'privateKeyPem': privateKeyPem,
      });
      await localFileCache.saveFileEncrypted(
        fileId: file.id!,
        key: result['key'] as Uint8List,
        nonce: result['nonce'] as Uint8List,
        encryptedData: result['encryptedData'] as Uint8List,
        originalName: originalFileName,
      );
      plaintext = await _decryptFromCache(
        file.id!,
        result['key'] as Uint8List,
        result['nonce'] as Uint8List,
      );
    }

    return plaintext;
  }

  Future<Uint8List> _decryptFromCache(
    String fileId,
    Uint8List key,
    Uint8List nonce,
  ) async {
    return (await localFileCache.getFileDecrypted(fileId))!;
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
