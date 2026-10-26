import 'package:get/get.dart';
import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/api_client.dart';
import 'package:vaulth_app/server/exception/not_found_exception.dart';
import 'package:vaulth_app/server/exception/token_auth_exception.dart';
import 'package:vaulth_app/server/exception/unknown_error_exception.dart';
import 'package:vaulth_app/server/exception/username_already_exists_exception.dart';
import 'package:vaulth_app/server/exception/validation_error_exception.dart';
import 'package:vaulth_app/server/model/user/recovery_data_response.dart';
import 'package:vaulth_app/server/model/user/update_keys_request.dart';
import 'package:vaulth_app/server/model/user/update_recovery_keys_request.dart';
import 'package:vaulth_app/server/model/user/update_user_request.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto.dart';
import 'package:vaulth_app/server/repository/user/user_interface.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

class UserRepository implements UserInterface {
  final ApiClient _apiClient;
  final Config _config;

  final AuthLocalStorage _authLocalStorage;

  UserRepository(this._apiClient, this._config, this._authLocalStorage);

  @override //get
  Future<UserProfileDto?> getCurrentUserProfile() async {
    try {
      final resp = await _apiClient.get('${_config.userPath}/me');
      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();

          final user = UserProfileDto.fromJson(resp.body);

          await _authLocalStorage.saveUserInfo(user);

          return user;
        case 400:
          throw ValidationErrorException("Проверьте правильность данных");
        case 401:
          throw TokenAuthException("Попробуйте снова");
        case 404:
          throw NotFoundException("Пользователя не существует");
        case 409:
          throw UsernameAlreadyExistsException("username занят");
        default:
          throw UnknownErrorException();
      }
    } catch (e, s) {
      Logger.d("getCurrentUserProfile: $e\n$s", tag: "UserRepository");
      _rethrowOrWrap(e, s);
    }
  }

  @override //get
  Future<RecoveryDataResponse> getRecoveryData() async {
    try {
      final resp = await _apiClient.get('${_config.userPath}/me/recovery-data');
      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return RecoveryDataResponse.fromJson(resp.body);
        case 400:
          throw ValidationErrorException("Проверьте правильность данных");
        case 401:
          throw TokenAuthException("Попробуйте снова");
        case 404:
          throw NotFoundException("Пользователя не существует");
        case 409:
          throw UsernameAlreadyExistsException("username занят");
        default:
          throw UnknownErrorException();
      }
    } catch (e, s) {
      Logger.d("getRecoveryData: $e\n$s", tag: "UserRepository");
      _rethrowOrWrap(e, s);
    }
  }

  @override //get
  Future<UserProfileDto> getUserProfileById({required String id}) async {
    try {
      final resp = await _apiClient.get('${_config.userPath}/$id');
      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return UserProfileDto.fromJson(resp.body);
        case 400:
          throw ValidationErrorException("Проверьте правильность данных");
        case 401:
          throw TokenAuthException("Попробуйте снова");
        case 404:
          throw NotFoundException("Пользователя не существует");
        case 409:
          throw UsernameAlreadyExistsException("username занят");
        default:
          throw UnknownErrorException();
      }
    } catch (e, s) {
      Logger.d("getUserProfileById: $e\n$s", tag: "UserRepository");
      _rethrowOrWrap(e, s);
    }
  }

  @override //put
  Future<UserProfileDto> updateCurrentUser({
    required UpdateUserRequest request,
  }) async {
    try {
      final resp = await _apiClient.put(
        '${_config.userPath}/me',
        request.toJson(),
      );
      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return UserProfileDto.fromJson(resp.body);
        case 400:
          throw ValidationErrorException("Проверьте правильность данных");
        case 401:
          throw TokenAuthException("Попробуйте снова");
        case 404:
          throw NotFoundException("Пользователя не существует");
        case 409:
          throw UsernameAlreadyExistsException("username занят");
        default:
          throw UnknownErrorException();
      }
    } catch (e, s) {
      Logger.d("updateCurrentUser: $e\n$s", tag: "UserRepository");
      _rethrowOrWrap(e, s);
    }
  }

  @override //post
  Future<void> updateKeys({required UpdateKeysRequest request}) async {
    try {
      final resp = await _apiClient.post(
        '${_config.userPath}/keys/update',
        request.toJson(),
      );
      switch (resp.statusCode) {
        case 200:
          Get.snackbar("Успех!", "Ключи обновлены успешно");
          return;
        case 400:
          throw ValidationErrorException("Проверьте правильность данных");
        case 401:
          throw TokenAuthException("Попробуйте снова");
        case 404:
          throw NotFoundException("Пользователя не существует");
        case 409:
          throw UsernameAlreadyExistsException("username занят");
        default:
          throw UnknownErrorException();
      }
    } catch (e, s) {
      Logger.d("updateKeys: $e\n$s", tag: "UserRepository");
      _rethrowOrWrap(e, s);
    }
  }

  @override //post
  Future<void> updateRecoveryKeys({
    required UpdateRecoveryKeysRequest request,
  }) async {
    try {
      final resp = await _apiClient.post(
        '${_config.userPath}/keys/recovery/update',
        request.toJson(),
      );
      switch (resp.statusCode) {
        case 200:
          Get.snackbar("Успех!", "Ключи восстановления обновлены успешно");
          return;
        case 400:
          throw ValidationErrorException("Проверьте правильность данных");
        case 401:
          throw TokenAuthException("Попробуйте снова");
        case 404:
          throw NotFoundException("Пользователя не существует");
        case 409:
          throw UsernameAlreadyExistsException("username занят");
        default:
          throw UnknownErrorException();
      }
    } catch (e, s) {
      Logger.d("updateRecoveryKeys: $e\n$s", tag: "UserRepository");
      _rethrowOrWrap(e, s);
    }
  }

  Never _rethrowOrWrap(Object e, StackTrace s) {
    if (e is ValidationErrorException ||
        e is TokenAuthException ||
        e is NotFoundException ||
        e is UsernameAlreadyExistsException ||
        e is UnknownErrorException) {
      Error.throwWithStackTrace(e, s);
    }
    Error.throwWithStackTrace(UnknownErrorException(), s);
  }
}