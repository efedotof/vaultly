import 'dart:convert';
import 'package:get/get.dart';
import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/api_client.dart';
import 'package:vaulth_app/server/exception/auth_error_exception.dart';
import 'package:vaulth_app/server/exception/rate_limit_exception.dart';
import 'package:vaulth_app/server/exception/token_auth_exception.dart';
import 'package:vaulth_app/server/exception/totp_required_exception.dart';
import 'package:vaulth_app/server/exception/unknown_error_exception.dart';
import 'package:vaulth_app/server/exception/username_already_exists_exception.dart';
import 'package:vaulth_app/server/exception/validation_error_exception.dart';
import 'package:vaulth_app/server/model/auth/auth_info.dart';
import 'package:vaulth_app/server/model/auth/login_request.dart';
import 'package:vaulth_app/server/model/auth/login_with_totp_request.dart';
import 'package:vaulth_app/server/model/auth/logout_request.dart';
import 'package:vaulth_app/server/model/auth/recover_request.dart';
import 'package:vaulth_app/server/model/auth/recovery_challenge_request.dart';
import 'package:vaulth_app/server/model/auth/recovery_challenge_response.dart';
import 'package:vaulth_app/server/model/auth/register_request.dart';
import 'package:vaulth_app/server/model/auth/token_validation_request.dart';
import 'package:vaulth_app/server/model/auth/totp_disable_request.dart';
import 'package:vaulth_app/server/model/auth/totp_setup_response.dart';
import 'package:vaulth_app/server/model/auth/totp_verify_request.dart';
import 'package:vaulth_app/server/model/auth/totp_verify_response.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto.dart';
import 'package:vaulth_app/server/repository/user/user_interface.dart';
import 'package:vaulth_app/server/service/key/key_manager.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';
import '../../model/auth/auth_response.dart';
import 'auth_interface.dart';

class AuthRepository implements AuthInterface {
  static const _tag = 'AuthRepository';

  final Config _config;
  final ApiClient _apiClient;
  final AuthLocalStorage _localStorage;

  AuthRepository(this._apiClient, this._config, this._localStorage);

  String _mask(String? value) {
    if (value == null || value.isEmpty) return '<empty>';
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}…${value.substring(value.length - 4)}';
  }

  Never _rethrowOrWrap(Object e, StackTrace s, String method) {
    Logger.d('$method: ${e.runtimeType}: $e\n$s', tag: _tag);

    if (e is TotpRequiredException ||
        e is AuthErrorException ||
        e is RateLimitException ||
        e is TokenAuthException ||
        e is ValidationErrorException ||
        e is UsernameAlreadyExistsException ||
        e is UnknownErrorException) {
      Error.throwWithStackTrace(e, s);
    }
    Error.throwWithStackTrace(UnknownErrorException(), s);
  }

  Future<String> _getPublicKey(String password) async {
    final keyManager = Get.find<KeyManagerService>();
    keyManager.clearUserKeys();
    Logger.d('_getPublicKey: start', tag: _tag);

    String? publicKey;
    try {
      publicKey = await keyManager.getUserPublicKey();
      Logger.d(
        '_getPublicKey: getUserPublicKey → ${publicKey != null ? "found" : "null"}',
        tag: _tag,
      );
    } catch (e, s) {
      Logger.e(
        '_getPublicKey: getUserPublicKey failed',
        error: e,
        stackTrace: s,
        tag: _tag,
      );
      rethrow;
    }

    if (publicKey == null || publicKey.isEmpty) {
      Logger.d('_getPublicKey: генерируем новую пару', tag: _tag);
      try {
        publicKey = await keyManager.generateAndStoreUserKeyPair(password);
        Logger.d(
          '_getPublicKey: сгенерировано, len=${publicKey.length}',
          tag: _tag,
        );
      } catch (e, s) {
        Logger.e(
          '_getPublicKey: generateAndStoreUserKeyPair failed',
          error: e,
          stackTrace: s,
          tag: _tag,
        );
        rethrow;
      }
    } else {
      Logger.d('_getPublicKey: используем существующую пару', tag: _tag);
    }

    Logger.d('_getPublicKey: проверяем пару...', tag: _tag);
    final isValid = await keyManager.verifyStoredKeyPairMatches(
      password: password,
    );
    Logger.d('_getPublicKey: verify=$isValid', tag: _tag);

    if (!isValid) {
      final privateKey = await keyManager.getPrivateKey(password);
      if (privateKey == null) {
        Logger.d(
          '_getPublicKey: приватный ключ не загрузился (пароль?)',
          tag: _tag,
        );
        throw ValidationErrorException(
          'Не удалось загрузить приватный ключ. Проверьте пароль.',
        );
      }
      Logger.d(
        '_getPublicKey: пара не сходится (storage corruption?)',
        tag: _tag,
      );
      throw ValidationErrorException('Ключи не сходятся. Восстановите доступ.');
    }

    return publicKey;
  }

  Future<UserProfileDto?> _loadUserData() async {
    Logger.d('_loadUserData: запрос профиля', tag: _tag);
    final user = await Get.find<UserInterface>().getCurrentUserProfile();
    if (user == null) {
      Logger.d('_loadUserData: профиль не получен (null)', tag: _tag);
      return null;
    }
    await _localStorage.saveUserInfo(user);
    Logger.d('_loadUserData: профиль сохранён (id=${user.id})', tag: _tag);
    return user;
  }

  @override
  Future<AuthInfo?> login({required LoginRequest request}) async {
    final url = '${_config.authPath}/login';
    Logger.d('login: POST $url user=${request.username}', tag: _tag);
    try {
      final resp = await _apiClient.post(url, request.toJson());
      Logger.d('login: статус ${resp.statusCode}', tag: _tag);

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") {
            Logger.d('login: пустое тело ответа', tag: _tag);
            throw UnknownErrorException();
          }
          final authResp = AuthResponse.fromJson(resp.body);
          Logger.d('login: token=${_mask(authResp.accessToken)}', tag: _tag);
          if (authResp.accessToken == null || authResp.accessToken == "") {
            Logger.d('login: accessToken пуст', tag: _tag);
            throw AuthErrorException();
          }
          final auth = AuthInfo();
          auth.authResponse = authResp;
          await _localStorage.saveAuthData(authResp);
          Logger.d('login: auth data сохранена локально', tag: _tag);
          final user = await _loadUserData();
          auth.user = user;
          await _localStorage.savePassword(request.password);
          Logger.d('login: пароль сохранён локально', tag: _tag);
          return auth;

        case 400:
          Logger.d('login: 400 validation', tag: _tag);
          throw ValidationErrorException("Неправильный формат!");
        case 401:
          final body = resp.body is Map<String, dynamic>
              ? resp.body as Map<String, dynamic>
              : <String, dynamic>{};
          Logger.d('login: 401 body keys=${body.keys.toList()}', tag: _tag);
          if (body['error'] == 'totp_required') {
            Logger.d('login: требуется TOTP', tag: _tag);

            await _localStorage.savePassword(request.password);
            throw TotpRequiredException(body['preAuthToken'] as String);
          }
          throw AuthErrorException();
        case 429:
          Logger.d('login: 429 rate limit', tag: _tag);
          throw RateLimitException();
        case 500:
          Logger.d('login: 500 server error', tag: _tag);
          throw UnknownErrorException();
        default:
          Logger.d('login: неожиданный статус ${resp.statusCode}', tag: _tag);
          throw UnknownErrorException();
      }
    } catch (e, s) {
      _rethrowOrWrap(e, s, 'login');
    }
  }

  @override
  Future<void> logout({required LogoutRequest request}) async {
    final url = '${_config.authPath}/logout';
    Logger.d('logout: POST $url', tag: _tag);
    try {
      final resp = await _apiClient.post(url, request.toJson());
      Logger.d('logout: статус ${resp.statusCode}', tag: _tag);

      if (resp.statusCode == 200) {
        await _localStorage.clearAuthData();
        await _localStorage.deletePassword();
        Logger.d('logout: локальные данные очищены', tag: _tag);
        Get.toNamed('/');
        Logger.d('logout: переход на /', tag: _tag);
      } else {
        Logger.d('logout: неожиданный статус ${resp.statusCode}', tag: _tag);
      }
    } catch (e, s) {
      _rethrowOrWrap(e, s, 'logout');
    }
  }

  @override
  Future<AuthInfo> recovery({required RecoverRequest request}) async {
    final url = '${_config.authPath}/recover';
    Logger.d('recovery: POST $url', tag: _tag);
    try {
      final resp = await _apiClient.post(url, request.toJson());
      Logger.d('recovery: статус ${resp.statusCode}', tag: _tag);

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") {
            Logger.d('recovery: пустое тело ответа', tag: _tag);
            throw UnknownErrorException();
          }
          final authResp = AuthResponse.fromJson(resp.body);
          Logger.d('recovery: token=${_mask(authResp.accessToken)}', tag: _tag);
          if (authResp.accessToken == null || authResp.accessToken == "") {
            Logger.d('recovery: accessToken пуст', tag: _tag);
            throw AuthErrorException();
          }
          final auth = AuthInfo();
          auth.authResponse = authResp;
          await _localStorage.saveAuthData(authResp);
          final user = await _loadUserData();
          auth.user = user;
          Logger.d('recovery: успешно, user=${user?.id}', tag: _tag);
          return auth;
        case 400:
          Logger.d('recovery: 400', tag: _tag);
          throw UnknownErrorException();
        case 429:
          Logger.d('recovery: 429 rate limit', tag: _tag);
          throw RateLimitException();
        case 500:
          Logger.d('recovery: 500', tag: _tag);
          throw UnknownErrorException();
        default:
          Logger.d(
            'recovery: неожиданный статус ${resp.statusCode}',
            tag: _tag,
          );
          throw UnknownErrorException();
      }
    } catch (e, s) {
      _rethrowOrWrap(e, s, 'recovery');
    }
  }

  @override
  Future<RecoveryChallengeResponse> recoveryChallenge({
    required RecoveryChallengeRequest request,
  }) async {
    final url = '${_config.authPath}/recover/challenge';
    Logger.d(
      'recoveryChallenge: POST $url publicKey=${request.publicKey}',
      tag: _tag,
    );
    try {
      final resp = await _apiClient.post(url, request.toJson());
      Logger.d('recoveryChallenge: статус ${resp.statusCode}', tag: _tag);

      switch (resp.statusCode) {
        case 200:
          if (resp.body == "" || resp.body == null) {
            Logger.d('recoveryChallenge: пустое тело', tag: _tag);
            throw UnknownErrorException();
          }
          Logger.d('recoveryChallenge: challenge получен', tag: _tag);
          return RecoveryChallengeResponse.fromJson(resp.body);
        case 400:
          Logger.d('recoveryChallenge: 400', tag: _tag);
          throw ValidationErrorException(
            "Проверьте правильность заполнения данных",
          );
        case 429:
          Logger.d('recoveryChallenge: 429', tag: _tag);
          throw RateLimitException();
        case 500:
          Logger.d('recoveryChallenge: 500', tag: _tag);
          throw UnknownErrorException();
        default:
          Logger.d(
            'recoveryChallenge: неожиданный статус ${resp.statusCode}',
            tag: _tag,
          );
          throw UnknownErrorException();
      }
    } catch (e, s) {
      _rethrowOrWrap(e, s, 'recoveryChallenge');
    }
  }

  @override
  Future<AuthInfo> registration({required RegisterRequest request}) async {
    final url = '${_config.authPath}/register';
    if (request.email == null ||
        request.firstName == null ||
        request.lastName == null) {
      throw ValidationErrorException(
        'Проверьте username / password / publicKey',
      );
    }
    Logger.d(
      'registration: POST $url username=${request.username} email=${request.email}',
      tag: _tag,
    );
    try {
      final publicKey = await _getPublicKey(request.password);
      final newRequest = RegisterRequest(
        username: request.username,
        password: request.password,
        firstName: request.firstName,
        lastName: request.lastName,
        email: request.email,
        publicKey: publicKey,
      );
      final resp = await _apiClient.post(url, newRequest.toJson());
      Logger.d('registration: статус ${resp.statusCode}', tag: _tag);

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") {
            Logger.d('registration: пустое тело', tag: _tag);
            throw UnknownErrorException();
          }
          final authResp = AuthResponse.fromJson(resp.body);
          Logger.d(
            'registration: token=${_mask(authResp.accessToken)}',
            tag: _tag,
          );
          if (authResp.accessToken == null || authResp.accessToken == "") {
            Logger.d('registration: accessToken пуст', tag: _tag);
            throw AuthErrorException();
          }
          final auth = AuthInfo();
          auth.authResponse = authResp;
          await _localStorage.saveAuthData(authResp);
          final user = await _loadUserData();
          auth.user = user;
          await _localStorage.savePassword(request.password);
          Logger.d('registration: успешно, user=${user?.id}', tag: _tag);
          return auth;

        case 400:
          final raw = resp.body;
          Map<String, dynamic> body;

          if (raw is Map<String, dynamic>) {
            body = raw;
          } else if (raw is String && raw.isNotEmpty) {
            try {
              final decoded = jsonDecode(raw);
              body = decoded is Map
                  ? Map<String, dynamic>.from(decoded)
                  : <String, dynamic>{};
            } catch (e) {
              Logger.d('registration: jsonDecode error $e', tag: _tag);
              body = <String, dynamic>{};
            }
          } else {
            body = <String, dynamic>{};
          }

          final message = (body['message'] as String?)?.trim() ?? '';
          Logger.d('registration: 400 message="$message"', tag: _tag);

          if (message.isEmpty && body['timestamp'] != null) {
            Logger.d('registration: 400 без message', tag: _tag);
            throw ValidationErrorException(
              'Проверьте username / password / publicKey',
            );
          }

          final lower = message.toLowerCase();
          if (lower.contains('already exists') ||
              lower.contains('already taken') ||
              lower.contains('уже существует')) {
            Logger.d('registration: username занят', tag: _tag);
            throw UsernameAlreadyExistsException(message);
          }
          throw ValidationErrorException(
            message.isNotEmpty ? message : 'Ошибка регистрации',
          );
        case 429:
          Logger.d('registration: 429 rate limit', tag: _tag);
          throw RateLimitException();
        case 500:
          Logger.d('registration: 500', tag: _tag);
          throw UnknownErrorException();
        default:
          Logger.d(
            'registration: неожиданный статус ${resp.statusCode}',
            tag: _tag,
          );
          throw UnknownErrorException();
      }
    } catch (e, s) {
      _rethrowOrWrap(e, s, 'registration');
    }
  }

  @override
  Future<void> totpDisable({required TotpDisableRequest request}) async {
    final url = '${_config.authPath}/totp/disable';
    Logger.d('totpDisable: POST $url', tag: _tag);
    try {
      final resp = await _apiClient.post(url, request.toJson());
      Logger.d('totpDisable: статус ${resp.statusCode}', tag: _tag);

      switch (resp.statusCode) {
        case 200:
          Logger.d('totpDisable: успешно', tag: _tag);
          break;
        case 400:
          Logger.d('totpDisable: 400 (неверный код)', tag: _tag);
          throw ValidationErrorException("Неверный TOTP или резервный код");
        case 401:
          Logger.d('totpDisable: 401', tag: _tag);
          throw TokenAuthException("Сессия истекла");
        case 500:
          Logger.d('totpDisable: 500', tag: _tag);
          throw UnknownErrorException();
        default:
          Logger.d(
            'totpDisable: неожиданный статус ${resp.statusCode}',
            tag: _tag,
          );
          throw UnknownErrorException();
      }
    } catch (e, s) {
      _rethrowOrWrap(e, s, 'totpDisable');
    }
  }

  @override
  Future<AuthInfo> totpLogin({required LoginWithTotpRequest request}) async {
    final url = '${_config.authPath}/login/totp';
    Logger.d('totpLogin: POST $url', tag: _tag);
    try {
      final resp = await _apiClient.post(url, request.toJson());
      Logger.d('totpLogin: статус ${resp.statusCode}', tag: _tag);

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") {
            Logger.d('totpLogin: пустое тело', tag: _tag);
            throw UnknownErrorException();
          }
          final authResp = AuthResponse.fromJson(resp.body);
          Logger.d(
            'totpLogin: token=${_mask(authResp.accessToken)}',
            tag: _tag,
          );
          if (authResp.accessToken == null || authResp.accessToken == "") {
            Logger.d('totpLogin: accessToken пуст', tag: _tag);
            throw AuthErrorException();
          }
          final auth = AuthInfo();
          auth.authResponse = authResp;
          await _localStorage.saveAuthData(authResp);
          final user = await _loadUserData();
          auth.user = user;
          Logger.d('totpLogin: успешно, user=${user?.id}', tag: _tag);
          return auth;
        case 400:
          Logger.d('totpLogin: 400 (некорректный код)', tag: _tag);
          throw ValidationErrorException("Некорректный код");
        case 401:
          Logger.d('totpLogin: 401 (неверный код или preAuthToken)', tag: _tag);
          throw AuthErrorException();
        case 429:
          Logger.d('totpLogin: 429 rate limit', tag: _tag);
          throw RateLimitException();
        case 500:
          Logger.d('totpLogin: 500', tag: _tag);
          throw UnknownErrorException();
        default:
          Logger.d(
            'totpLogin: неожиданный статус ${resp.statusCode}',
            tag: _tag,
          );
          throw UnknownErrorException();
      }
    } catch (e, s) {
      _rethrowOrWrap(e, s, 'totpLogin');
    }
  }

  @override
  Future<TotpSetupResponse> totpSetup() async {
    final url = '${_config.authPath}/totp/setup';
    Logger.d('totpSetup: POST $url', tag: _tag);
    try {
      final resp = await _apiClient.post(url, {});
      Logger.d('totpSetup: статус ${resp.statusCode}', tag: _tag);

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") {
            Logger.d('totpSetup: пустое тело', tag: _tag);
            throw UnknownErrorException();
          }
          Logger.d('totpSetup: успешно', tag: _tag);
          return TotpSetupResponse.fromJson(resp.body);
        case 400:
          Logger.d('totpSetup: 400 body=${resp.body}', tag: _tag);
          throw ValidationErrorException(resp.body.toString());
        case 401:
          Logger.d('totpSetup: 401', tag: _tag);
          throw TokenAuthException("Сессия истекла");
        case 500:
          Logger.d('totpSetup: 500', tag: _tag);
          throw UnknownErrorException();
        default:
          Logger.d(
            'totpSetup: неожиданный статус ${resp.statusCode}',
            tag: _tag,
          );
          throw UnknownErrorException();
      }
    } catch (e, s) {
      _rethrowOrWrap(e, s, 'totpSetup');
    }
  }

  @override
  Future<TotpVerifyResponse> totpVerify({
    required TotpVerifyRequest request,
  }) async {
    final url = '${_config.authPath}/totp/verify';
    Logger.d('totpVerify: POST $url', tag: _tag);
    try {
      final resp = await _apiClient.post(url, request.toJson());
      Logger.d('totpVerify: статус ${resp.statusCode}', tag: _tag);

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") {
            Logger.d('totpVerify: пустое тело', tag: _tag);
            throw UnknownErrorException();
          }
          Logger.d('totpVerify: успешно', tag: _tag);
          return TotpVerifyResponse.fromJson(resp.body);
        case 400:
          Logger.d('totpVerify: 400 (неверный код)', tag: _tag);
          throw TokenAuthException("Неверный TOTP код");
        case 401:
          Logger.d('totpVerify: 401', tag: _tag);
          throw TokenAuthException("Сессия истекла");
        case 500:
          Logger.d('totpVerify: 500', tag: _tag);
          throw UnknownErrorException();
        default:
          Logger.d(
            'totpVerify: неожиданный статус ${resp.statusCode}',
            tag: _tag,
          );
          throw UnknownErrorException();
      }
    } catch (e, s) {
      _rethrowOrWrap(e, s, 'totpVerify');
    }
  }

  @override
  Future<AuthInfo?> validate({required TokenValidationRequest request}) async {
    final url = '${_config.authPath}/validate';
    Logger.d('validate: POST $url token=${_mask(request.token)}', tag: _tag);
    try {
      final resp = await _apiClient.post(url, request.toJson());
      Logger.d('validate: статус ${resp.statusCode}', tag: _tag);

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") {
            Logger.d('validate: пустое тело', tag: _tag);
            throw UnknownErrorException();
          }
          final authResp = AuthResponse.fromJson(resp.body);
          Logger.d('validate: token=${_mask(authResp.accessToken)}', tag: _tag);
          if (authResp.accessToken == null || authResp.accessToken == "") {
            Logger.d('validate: accessToken пуст', tag: _tag);
            throw AuthErrorException();
          }
          final auth = AuthInfo();
          auth.authResponse = authResp;
          await _localStorage.saveAuthData(authResp);
          final user = await _loadUserData();
          auth.user = user;
          Logger.d('validate: успешно', tag: _tag);
          return auth;
        case 400:
          Logger.d('validate: 400', tag: _tag);
          throw ValidationErrorException("Неправильный формат!");
        case 401:
          Logger.d('validate: 401 — пробуем перелогин', tag: _tag);
          final auth = await _localStorage.loadAuthData();
          final password = await _localStorage.getPassword();

          Logger.d(
            'validate: сохранённый username=${auth?.username} token=${_mask(auth?.accessToken)} password=${password == null ? "<null>" : "<set>"}',
            tag: _tag,
          );

          if (auth == null ||
              auth.username == "" ||
              auth.username == null ||
              auth.accessToken == "" ||
              auth.accessToken == null ||
              password == "" ||
              password == null) {
            Logger.d('validate: недостаточно данных для перелогина', tag: _tag);
            throw UnknownErrorException();
          }

          Logger.d('validate: перелогин через login()', tag: _tag);
          final authInfo = await login(
            request: LoginRequest(username: auth.username!, password: password),
          );
          return authInfo;
        case 500:
          Logger.d('validate: 500', tag: _tag);
          throw UnknownErrorException();
        default:
          Logger.d(
            'validate: неожиданный статус ${resp.statusCode}',
            tag: _tag,
          );
          throw UnknownErrorException();
      }
    } catch (e, s) {
      _rethrowOrWrap(e, s, 'validate');
    }
  }
}
