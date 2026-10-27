import 'dart:io';
import 'package:get/get_connect.dart';
import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/api_client.dart';
import 'package:vaulth_app/server/exception/auth_error_exception.dart';
import 'package:vaulth_app/server/exception/not_found_exception.dart';
import 'package:vaulth_app/server/exception/rate_limit_exception.dart';
import 'package:vaulth_app/server/exception/unknown_error_exception.dart';
import 'package:vaulth_app/server/exception/validation_error_exception.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

import 'file_interface.dart';
import 'package:vaulth_app/server/model/file/check_duplicate_request.dart';
import 'package:vaulth_app/server/model/file/decryption_metadata.dart';
import 'package:vaulth_app/server/model/file/file_dto.dart';
import 'package:vaulth_app/server/model/file/link_file_request.dart';

class FileRepository implements FileInterface {
  final ApiClient _apiClient;
  final Config _config;

  FileRepository({required ApiClient apiClient, required Config config})
      : _apiClient = apiClient,
        _config = config;

  String get _base => _config.filePath;

  @override
  Future<FileDto> uploadShps({
    required String filePath,
    required String fileName,
    required bool isPublic,
    String? folderId,
    String? contentHash,
  }) async {
    try {
      final form = FormData({
        'file': MultipartFile(File(filePath), filename: fileName),
        'isPublic': isPublic.toString(),
        'folderId': ?folderId,
        'contentHash': ?contentHash,
      });

      final resp = await _apiClient.postMultipart('$_base/upload/shps', form);

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return FileDto.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException("Неправильный формат файла или параметров!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Нет прав на загрузку в эту папку");
        case 429:
          throw RateLimitException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FileRepository: uploadShps");
      throw UnknownErrorException();
    }
  }

  @override
  Future<FileDto> uploadPublicFile({
    required String filePath,
    required String fileName,
    String? folderId,
    String? contentHash,
  }) async {
    try {
      final form = FormData({
        'file': MultipartFile(File(filePath), filename: fileName),
        'folderId': ?folderId,
        'contentHash': ?contentHash,
      });

      final resp = await _apiClient.postMultipart('$_base/upload/public', form);

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return FileDto.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException("Неправильный формат файла или параметров!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Нет прав на загрузку в эту папку");
        case 429:
          throw RateLimitException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FileRepository: uploadPublicFile");
      throw UnknownErrorException();
    }
  }

  @override
  Future<Map<String, dynamic>> getAllFiles({int page = 0, int size = 20}) async {
    try {
      final resp = await _apiClient.get(
        _base,
        query: {"page": page.toString(), "size": size.toString()},
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null) throw UnknownErrorException();
          return _apiClient.jsonMap(resp.body);

        case 400:
          throw ValidationErrorException("Неправильная пагинация!");
        case 401:
          throw AuthErrorException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FileRepository: getAllFiles");
      throw UnknownErrorException();
    }
  }

  @override
  Future<Map<String, dynamic>> getRecentFiles({int page = 0, int size = 10}) async {
    try {
      final resp = await _apiClient.get(
        '$_base/recent',
        query: {"page": page.toString(), "size": size.toString()},
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null) throw UnknownErrorException();
          return _apiClient.jsonMap(resp.body);

        case 400:
          throw ValidationErrorException("Неправильная пагинация!");
        case 401:
          throw AuthErrorException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FileRepository: getRecentFiles");
      throw UnknownErrorException();
    }
  }

  @override
  Future<String> downloadFile({required String fileId}) async {
    try {
      final resp = await _apiClient.get('$_base/$fileId/download');

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          final body = _apiClient.jsonMap(resp.body);
          final url = body['url'];
          if (url == null || (url as String).isEmpty) throw UnknownErrorException();
          return url;

        case 400:
          throw ValidationErrorException("Некорректный запрос!");
        case 401:
          throw AuthErrorException();
        case 404:
          throw NotFoundException("Файл не найден");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FileRepository: downloadFile");
      throw UnknownErrorException();
    }
  }

  @override
  Future<DecryptionMetadata> getDecryptionMetadata({required String fileId}) async {
    try {
      final resp = await _apiClient.get('$_base/$fileId/content');

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return DecryptionMetadata.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException("Некорректный запрос!");
        case 401:
          throw AuthErrorException();
        case 404:
          throw NotFoundException("Файл не найден");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FileRepository: getDecryptionMetadata");
      throw UnknownErrorException();
    }
  }

  @override
  Future<void> deleteFile({required String fileId}) async {
    try {
      final resp = await _apiClient.delete('$_base/$fileId');

      switch (resp.statusCode) {
        case 200:
        case 204:
          return;

        case 400:
          throw ValidationErrorException("Некорректный запрос!");
        case 401:
          throw AuthErrorException();
        case 404:
          throw NotFoundException("Файл не найден");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FileRepository: deleteFile");
      throw UnknownErrorException();
    }
  }

  @override
  Future<Map<String, dynamic>> getNotes({int page = 0, int size = 20}) async {
    try {
      final resp = await _apiClient.get(
        '$_base/notes',
        query: {"page": page.toString(), "size": size.toString()},
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null) throw UnknownErrorException();
          return _apiClient.jsonMap(resp.body);

        case 400:
          throw ValidationErrorException("Неправильная пагинация!");
        case 401:
          throw AuthErrorException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FileRepository: getNotes");
      throw UnknownErrorException();
    }
  }

  @override
  Future<FileDto> createNote({
    required String filePath,
    required String fileName,
    String? folderId,
  }) async {
    try {
      final form = FormData({
        'file': MultipartFile(File(filePath), filename: fileName),
        'folderId': ?folderId,
      });

      final resp = await _apiClient.postMultipart('$_base/notes', form);

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return FileDto.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException("Неправильный формат заметки!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Нет прав на создание заметки в этой папке");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FileRepository: createNote");
      throw UnknownErrorException();
    }
  }

  @override
  Future<FileDto> updateNoteContent({
    required String noteId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final form = FormData({
        'file': MultipartFile(File(filePath), filename: fileName),
      });

      final resp = await _apiClient.putMultipart('$_base/notes/$noteId/content', form);

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return FileDto.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException("Неправильный формат заметки!");
        case 401:
          throw AuthErrorException();
        case 404:
          throw NotFoundException("Заметка не найдена");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FileRepository: updateNoteContent");
      throw UnknownErrorException();
    }
  }

  @override
  Future<bool> checkDuplicate({required CheckDuplicateRequest request}) async {
    try {
      final resp = await _apiClient.post(
        '$_base/check-duplicate',
        request.toJson(),
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null) throw UnknownErrorException();
          final body = _apiClient.jsonMap(resp.body);
          return body['exists'] == true;

        case 400:
          throw ValidationErrorException("Некорректный хеш или параметры!");
        case 401:
          throw AuthErrorException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FileRepository: checkDuplicate");
      throw UnknownErrorException();
    }
  }

  @override
  Future<FileDto> linkExistingFile({required LinkFileRequest request}) async {
    try {
      final resp = await _apiClient.post(
        '$_base/link',
        request.toJson(),
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return FileDto.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException("Неправильный формат или файл уже принадлежит другому пользователю!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Нет прав на этот контент");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FileRepository: linkExistingFile");
      throw UnknownErrorException();
    }
  }
}