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
import 'package:vaulth_app/server/service/logger/logger.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';
import '../../model/auth/auth_response.dart';
import 'auth_interface.dart';

class AuthRepository implements AuthInterface {
  final Config _config;
  final ApiClient _apiClient;
  final AuthLocalStorage _localStorage;

  AuthRepository(this._apiClient, this._config, this._localStorage);

  Future<UserProfileDto?> _loadUserData() async {
    final user = await Get.find<UserInterface>().getCurrentUserProfile();
    if (user == null) return null;
       await _localStorage.saveUserInfo(user);
    return user;
  }

  @override
  Future<AuthInfo?> login({required LoginRequest request}) async {
    try {
      final resp = await _apiClient.post('${_config.authPath}/login', request.toJson());

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();

          final authResp = AuthResponse.fromJson(resp.body);

          if (authResp.accessToken == null || authResp.accessToken == "") throw AuthErrorException();

          final auth = AuthInfo();
          auth.authResponse = authResp;

          await _localStorage.saveAuthData(authResp);

          final user = await _loadUserData();
          
          auth.user = user;
          
          await _localStorage.savePassword(request.password);
          return auth;

        case 400:
          throw ValidationErrorException("Неправильный формат!");
        case 401:
          final body = resp.body is Map<String, dynamic>
              ? resp.body as Map<String, dynamic>
              : <String, dynamic>{};

          if (body['error'] == 'totp_required') {
            throw TotpRequiredException(body['preAuthToken'] as String);
          }

          throw AuthErrorException();

        case 429:
          throw RateLimitException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "AuthRepository: login");
      throw UnknownErrorException();
    }
  }

  @override
  Future<void> logout({required LogoutRequest request}) async {
    try {
      final resp = await _apiClient.post('${_config.authPath}/logout', request.toJson());

      if (resp.statusCode == 200) {
        await _localStorage.clearAuthData();
        await _localStorage.deletePassword();

        Get.toNamed('/');
      }
    } catch (e) {
      Logger.d("error: $e", tag: "AuthRepository: login");
      throw UnknownErrorException();
    }
  }

  @override
  Future<AuthInfo> recovery({required RecoverRequest request}) async {
    try {
      final resp = await _apiClient.post('${_config.authPath}/recover', request.toJson());

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();

          final authResp = AuthResponse.fromJson(resp.body);

          if (authResp.accessToken == null || authResp.accessToken == "") throw AuthErrorException();

          final auth = AuthInfo();
          auth.authResponse = authResp;

          await _localStorage.saveAuthData(authResp);

          final user = await _loadUserData();
          auth.user = user;

          return auth;
        case 400:
          throw UnknownErrorException();
        case 429:
          throw RateLimitException();
        case 500:
          throw UnknownErrorException();
        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "AuthRepository: login");
      throw UnknownErrorException();
    }
  }

  @override
  Future<RecoveryChallengeResponse> recoveryChallenge({
    required RecoveryChallengeRequest request,
  }) async {
    try {
      final resp = await _apiClient.post('${_config.authPath}/recover/challenge', {});

      switch (resp.statusCode) {
        case 200:
          if (resp.body == "" || resp.body == null) throw UnknownErrorException();

          return RecoveryChallengeResponse.fromJson(resp.body);

        case 400:
          throw ValidationErrorException("Проверьте правильность заполнения данных");
        case 429:
          throw RateLimitException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "AuthRepository: login");
      throw UnknownErrorException();
    }
  }

  @override
  Future<AuthInfo> registration({required RegisterRequest request}) async {
    try {
      final resp = await _apiClient.post('${_config.authPath}/register', request.toJson());

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();

          final authResp = AuthResponse.fromJson(resp.body);

          if (authResp.accessToken == null || authResp.accessToken == "") throw AuthErrorException();

          final auth = AuthInfo();
          auth.authResponse = authResp;

          await _localStorage.saveAuthData(authResp);

          final user = await _loadUserData();
          auth.user = user;

          await _localStorage.savePassword(request.password);
          return auth;

        case 400:
          final raw = resp.body;
          Map<String, dynamic> body;

          if (raw is Map<String, dynamic>) {
            body = raw;
          } else if (raw is String && raw.isNotEmpty) {
            try {
              final decoded = jsonDecode(raw);
              body = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
            } catch (_) {
              body = <String, dynamic>{};
            }
          } else {
            body = <String, dynamic>{};
          }

          final message = (body['message'] as String?)?.trim() ?? '';

          if (message.isEmpty && body['timestamp'] != null) {
            throw ValidationErrorException('Проверьте username / password / publicKey');
          }

          final lower = message.toLowerCase();
          if (lower.contains('already exists') ||
              lower.contains('already taken') ||
              lower.contains('уже существует')) {
            throw UsernameAlreadyExistsException(message);
          }

          throw ValidationErrorException(
            message.isNotEmpty ? message : 'Ошибка регистрации',
          );
        case 429:
          throw RateLimitException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "AuthRepository: login");
      throw UnknownErrorException();
    }
  }

  @override
  Future<void> totpDisable({required TotpDisableRequest request}) async {
    try {
      final resp = await _apiClient.post('${_config.authPath}/totp/disable', request.toJson());
      switch (resp.statusCode) {
        case 200:
          break;
        case 400:
          break;
        case 401:
          break;

        case 500:
          break;

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "AuthRepository: login");
      throw UnknownErrorException();
    }
  }

  @override
  Future<void> totpLogin({required LoginWithTotpRequest request}) async {
    try {
      final resp = await _apiClient.post('${_config.authPath}/login/totp', request.toJson());

      switch (resp.statusCode) {
        case 200:
          break;
        case 400:
          break;
        case 401:
          break;
        case 429:
          break;
        case 500:
          break;

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "AuthRepository: login");
      throw UnknownErrorException();
    }
  }

  @override
  Future<TotpSetupResponse> totpSetup() async {
    try {
      final resp = await _apiClient.post('${_config.authPath}/totp/setup', {});

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return TotpSetupResponse.fromJson(resp.body);
        case 400:
          throw Exception(resp.body.toString());
        case 401:
          throw TokenAuthException("Произошла неизвестная ошибка");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "AuthRepository: login");
      throw UnknownErrorException();
    }
  }

  @override
  Future<TotpVerifyResponse> totpVerify({
    required TotpVerifyRequest request,
  }) async {
    try {
      final resp = await _apiClient.post('${_config.authPath}/totp/verify', request.toJson());

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return TotpVerifyResponse.fromJson(resp.body);
        case 400:
          throw TokenAuthException("Произошла неизвестная ошибка");
        case 401:
          throw TokenAuthException("Произошла неизвестная ошибка");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "AuthRepository: login");
      throw UnknownErrorException();
    }
  }

  @override
  Future<AuthInfo?> validate({required TokenValidationRequest request}) async {
    try {
      final resp = await _apiClient.post('${_config.authPath}/validate', {});

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();

          final authResp = AuthResponse.fromJson(resp.body);

          if (authResp.accessToken == null || authResp.accessToken == "") throw AuthErrorException();

          final auth = AuthInfo();
          auth.authResponse = authResp;

          await _localStorage.saveAuthData(authResp);

          final user = await _loadUserData();
          auth.user = user;

          return auth;
        case 400:
          throw ValidationErrorException("Неправильный формат!");
        case 401:
          final auth = await _localStorage.loadAuthData();
          final password = await _localStorage.getPassword();

          if (auth == null ||
              auth.username == "" ||
              auth.username == null ||
              auth.accessToken == "" ||
              auth.accessToken == null ||
              password == "" ||
              password == null) throw UnknownErrorException();
          final authInfo = await login(
              request: LoginRequest(username: auth.username!, password: password));
          return authInfo;
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "AuthRepository: login");
      throw UnknownErrorException();
    }
  }
}