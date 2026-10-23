import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/api_client.dart';
import 'package:vaulth_app/server/exception/auth_error_exception.dart';
import 'package:vaulth_app/server/exception/not_found_exception.dart';
import 'package:vaulth_app/server/exception/rate_limit_exception.dart';
import 'package:vaulth_app/server/exception/unknown_error_exception.dart';
import 'package:vaulth_app/server/exception/validation_error_exception.dart';
import 'package:vaulth_app/server/model/tempaccess/create_temp_link_request.dart';
import 'package:vaulth_app/server/model/tempaccess/temp_link_response.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

import 'temp_access_interface.dart';

import 'package:vaulth_app/server/model/file/decryption_metadata.dart';

class TempAccessRepository implements TempAccessInterface {
  final ApiClient _apiClient;
  final Config _config;

  TempAccessRepository({required ApiClient apiClient, required Config config})
    : _apiClient = apiClient,
      _config = config;

  String get _base => _config.tempAccessPath;

  @override
  Future<void> setFilePublic({
    required String fileId,
    required bool isPublic,
  }) async {
    try {
      final resp = await _apiClient.post('$_base/files/$fileId/public', {
        'isPublic': isPublic,
      });

      switch (resp.statusCode) {
        case 200:
          return;

        case 400:
          throw ValidationErrorException("Некорректный запрос!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException(
            "Вы можете менять публичность только своих файлов",
          );
        case 404:
          throw NotFoundException("Файл не найден");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "TempAccessRepository: setFilePublic");
      throw UnknownErrorException();
    }
  }

  @override
  Future<TempLinkResponse> createTempLink({
    required CreateTempLinkRequest request,
  }) async {
    try {
      final resp = await _apiClient.post(
        '$_base/temp-access/create',
        request.toJson(),
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return TempLinkResponse.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException(
            "Некорректная дата, файл не публичный или удалён!",
          );
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException(
            "Вы можете создавать ссылки только на свои файлы",
          );
        case 404:
          throw NotFoundException("Файл не найден");
        case 429:
          throw RateLimitException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "TempAccessRepository: createTempLink");
      throw UnknownErrorException();
    }
  }

  @override
  Future<void> checkTempLinkPassword({
    required String token,
    String? password,
  }) async {
    try {
      final resp = await _apiClient.post('$_base/temp-access/$token/metadata', {
        'password': ?password,
      });

      switch (resp.statusCode) {
        case 200:
          return;

        case 400:
          throw ValidationErrorException(
            "Неверный пароль или ссылка неактивна!",
          );
        case 401:
          throw AuthErrorException();
        case 404:
          throw NotFoundException("Ссылка не найдена или истекла");
        case 429:
          throw RateLimitException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "TempAccessRepository: checkTempLinkPassword");
      throw UnknownErrorException();
    }
  }

  @override
  Future<DecryptionMetadata> getDecryptionMetadata({
    required String token,
    String? password,
  }) async {
    try {
      final path = password != null
          ? '$_base/temp-access/$token/decryption-metadata?password=$password'
          : '$_base/temp-access/$token/decryption-metadata';

      final resp = await _apiClient.post(path, {});

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return DecryptionMetadata.fromJson(_apiClient.jsonMap(resp.body));

        case 400:
          throw ValidationErrorException(
            "Неверный пароль, ссылка истекла или лимит скачиваний исчерпан!",
          );
        case 401:
          throw AuthErrorException();
        case 404:
          throw NotFoundException("Ссылка не найдена");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "TempAccessRepository: getDecryptionMetadata");
      throw UnknownErrorException();
    }
  }

  @override
  Uri downloadUrl({required String token, String? password}) {
    final base = Uri.parse(_config.baseUrl);
    final path = '$_base/temp-access/$token/download';
    return base.replace(
      path: path,
      queryParameters: password != null ? {'password': password} : null,
    );
  }
}
