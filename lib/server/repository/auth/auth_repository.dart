import 'package:dio/dio.dart';
import 'package:vaulth_app/server/model/auth/auth_response/auth_response.dart';
import 'package:vaulth_app/server/model/auth/login_request/login_request.dart';
import 'package:vaulth_app/server/model/auth/logout_request/logout_request.dart';
import 'package:vaulth_app/server/model/auth/recover_request/recover_request.dart';
import 'package:vaulth_app/server/model/auth/register_request/register_request.dart';
import 'package:vaulth_app/server/model/auth/token_validation_request/token_validation_request.dart';

import 'auth_interface.dart';

class AuthRepository implements AuthInterface {
  final Dio _dio;
  final String authAddress;
  String? _accessToken;

  AuthRepository({required this.authAddress})
    : _dio = Dio(
        BaseOptions(
          baseUrl: authAddress,
          connectTimeout: const Duration(seconds: 40),
          receiveTimeout: const Duration(seconds: 40),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
      ),
    );
  }

  @override
  void setAccessToken(String token) {
    _accessToken = token;
  }

  void clearAccessToken() {
    _accessToken = null;
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post('/register', data: request.toJson());
      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      _accessToken = authResponse.accessToken;
      return authResponse;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/login', data: request.toJson());
      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      _accessToken = authResponse.accessToken;
      return authResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final data = e.response?.data;
        if (data is Map && data['error'] == 'totp_required') {
          throw TotpRequiredException(data['message'] ?? 'TOTP code required');
        }
      }
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResponse> validateToken(TokenValidationRequest request) async {
    try {
      final response = await _dio.post('/validate', data: request.toJson());
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout(LogoutRequest request) async {
    try {
      await _dio.post('/logout', data: request.toJson());
    } on DioException catch (e) {
      throw _handleDioError(e);
    } finally {
      clearAccessToken();
    }
  }

  @override
  Future<String> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data as String;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    final message = e.response?.data?['message'] ?? e.message;
    return Exception('Network error: $message');
  }

  @override
  Future<AuthResponse> recoverAccess({required RecoverRequest request}) async {
    try {
      final response = await _dio.post('/recover', data: request.toJson());
      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      _accessToken = authResponse.accessToken;
      return authResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final data = e.response?.data;
        if (data is Map && data['error'] == 'totp_required') {
          throw TotpRequiredException(data['message'] ?? 'TOTP code required');
        }
      }
      throw _handleDioError(e);
    }
  }
}

class TotpRequiredException implements Exception {
  final String message;
  TotpRequiredException(this.message);
  @override
  String toString() => 'TotpRequiredException: $message';
}
