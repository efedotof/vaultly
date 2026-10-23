import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/api_client.dart';
import 'package:vaulth_app/server/exception/auth_error_exception.dart';
import 'package:vaulth_app/server/exception/not_found_exception.dart';
import 'package:vaulth_app/server/exception/rate_limit_exception.dart';
import 'package:vaulth_app/server/exception/unknown_error_exception.dart';
import 'package:vaulth_app/server/exception/validation_error_exception.dart';
import 'package:vaulth_app/server/model/file/file_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_access_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_create_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_move_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_share_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_update_dto.dart';
import 'package:vaulth_app/server/model/page_dto.dart';
import 'package:vaulth_app/server/repository/folder/folder_interface.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

class FolderRepository implements FolderInterface {
  final ApiClient _apiClient;
  final Config _config;

  FolderRepository({required ApiClient apiClient, required Config config})
      : _apiClient = apiClient,
        _config = config;

  String get _base => _config.folderPath;

  @override
  Future<FolderDto> createFolder(FolderCreateDto request) async {
    try {
      final resp = await _apiClient.post(_base, request.toJson());

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return FolderDto.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException("Неправильное имя или параметры папки!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Нет прав на создание папки здесь");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FolderRepository: createFolder");
      throw UnknownErrorException();
    }
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    try {
      final resp = await _apiClient.delete('$_base/$folderId');

      switch (resp.statusCode) {
        case 200:
        case 204:
          return;

        case 400:
          throw ValidationErrorException("Некорректный запрос!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Нет прав на удаление этой папки");
        case 404:
          throw NotFoundException("Папка не найдена");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FolderRepository: deleteFolder");
      throw UnknownErrorException();
    }
  }

  @override
  Future<FolderDto> renameFolder(String folderId, FolderUpdateDto request) async {
    try {
      final resp = await _apiClient.put('$_base/$folderId', request.toJson());

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return FolderDto.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException("Неправильное имя папки или имя уже занято!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Нет прав на переименование этой папки");
        case 404:
          throw NotFoundException("Папка не найдена");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FolderRepository: renameFolder");
      throw UnknownErrorException();
    }
  }

  @override
  Future<FileDto> addFileToFolder(String folderId, String fileId) async {
    try {
      final resp = await _apiClient.post(
        '$_base/$folderId/files',
        {'fileId': fileId},
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return FileDto.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException("Некорректный запрос!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Нет прав на эту папку или файл");
        case 404:
          throw NotFoundException("Папка или файл не найдены");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FolderRepository: addFileToFolder");
      throw UnknownErrorException();
    }
  }

  @override
  Future<List<FileDto>> moveFiles(FolderMoveDto request) async {
    try {
      final resp = await _apiClient.post('$_base/move', request.toJson());

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null) throw UnknownErrorException();
          return (resp.body as List)
              .map((e) => FileDto.fromJson(_apiClient.jsonMap(e)))
              .toList();

        case 400:
          throw ValidationErrorException("Некорректный запрос!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Нет прав на перемещение файлов");
        case 404:
          throw NotFoundException("Папка или файл не найдены");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FolderRepository: moveFiles");
      throw UnknownErrorException();
    }
  }

  @override
  Future<FileDto> removeFileFromFolder(String folderId, String fileId) async {
    try {
      final resp = await _apiClient.delete('$_base/$folderId/files/$fileId');

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return FileDto.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException("Некорректный запрос!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Нет прав на эту папку или файл");
        case 404:
          throw NotFoundException("Папка или файл не найдены");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FolderRepository: removeFileFromFolder");
      throw UnknownErrorException();
    }
  }

  @override
  Future<FolderDto> closeFolderForOthers(String folderId) async {
    try {
      final resp = await _apiClient.post('$_base/$folderId/close', {});

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return FolderDto.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException("Некорректный запрос!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Только владелец может закрыть папку");
        case 404:
          throw NotFoundException("Папка не найдена");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FolderRepository: closeFolderForOthers");
      throw UnknownErrorException();
    }
  }

  @override
  Future<List<FolderAccessDto>> shareFolder(
    String folderId,
    FolderShareDto request,
  ) async {
    try {
      final resp = await _apiClient.post(
        '$_base/$folderId/share',
        request.toJson(),
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null) throw UnknownErrorException();
          return (resp.body as List)
              .map((e) => FolderAccessDto.fromJson(_apiClient.jsonMap(e)))
              .toList();

        case 400:
          throw ValidationErrorException("Некорректный запрос!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Нет прав на шаринг этой папки");
        case 404:
          throw NotFoundException("Папка или пользователь не найдены");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FolderRepository: shareFolder");
      throw UnknownErrorException();
    }
  }

  @override
  Future<bool> checkFolderAccess(
    String folderId,
    FolderAccessDto request,
  ) async {
    try {
      final resp = await _apiClient.post(
        '$_base/$folderId/access/check',
        request.toJson(),
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null) throw UnknownErrorException();
          if (resp.body is bool) return resp.body as bool;
          final body = _apiClient.jsonMap(resp.body);
          return body['result'] == true || body['allowed'] == true;

        case 400:
          throw ValidationErrorException("Некорректный запрос!");
        case 401:
          throw AuthErrorException();
        case 403:
          return false;
        case 429:
          throw RateLimitException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FolderRepository: checkFolderAccess");
      throw UnknownErrorException();
    }
  }

  @override
  Future<List<FolderDto>> getFolderTree() async {
    try {
      final resp = await _apiClient.get('$_base/tree');

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null) throw UnknownErrorException();
          return (resp.body as List)
              .map((e) => FolderDto.fromJson(_apiClient.jsonMap(e)))
              .toList();

        case 401:
          throw AuthErrorException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FolderRepository: getFolderTree");
      throw UnknownErrorException();
    }
  }

  @override
  Future<PageDto<FileDto>> getFolderFiles(
    String folderId, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final resp = await _apiClient.get(
        '$_base/$folderId/files',
        query: {"page": page.toString(), "size": size.toString()},
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null) throw UnknownErrorException();
          return PageDto<FileDto>.fromJson(
            _apiClient.jsonMap(resp.body),
            (json) => FileDto.fromJson(json),
          );

        case 400:
          throw ValidationErrorException("Неправильная пагинация!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Нет прав на эту папку");
        case 404:
          throw NotFoundException("Папка не найдена");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FolderRepository: getFolderFiles");
      throw UnknownErrorException();
    }
  }

  @override
  Future<void> setFolderPassword(String folderId, String? password) async {
    try {
      final resp = await _apiClient.post(
        '$_base/$folderId/password',
        {'password': password},
      );

      switch (resp.statusCode) {
        case 200:
        case 204:
          return;

        case 400:
          throw ValidationErrorException("Некорректный пароль!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException("Только владелец может установить пароль");
        case 404:
          throw NotFoundException("Папка не найдена");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "FolderRepository: setFolderPassword");
      throw UnknownErrorException();
    }
  }
}