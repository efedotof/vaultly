import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:vaulth_app/server/model/auth/auth_response/auth_response.dart';
import 'package:vaulth_app/server/model/auth/login_request/login_request.dart';
import 'package:vaulth_app/server/model/auth/logout_request/logout_request.dart';
import 'package:vaulth_app/server/model/auth/register_request/register_request.dart';
import 'package:vaulth_app/server/model/auth/token_validation_request/token_validation_request.dart';
import 'auth_interface.dart';

class AuthRepository implements AuthInterface {
  final Dio _dio;
  final String authAddress;

  AuthRepository({required this.authAddress})
    : _dio = Dio(
        BaseOptions(
          baseUrl: authAddress,
          connectTimeout: const Duration(seconds: 40),
          receiveTimeout: const Duration(seconds: 40),
        ),
      );

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    debugPrint(
      '[AuthRepository] register called with password: ${request.password}',
    );
    try {
      final response = await _dio.post('/register', data: request.toJson());
      debugPrint('[AuthRepository] register succeeded');
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[AuthRepository] register error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    debugPrint(
      '[AuthRepository] login called for password: ${request.password}',
    );
    try {
      final response = await _dio.post('/login', data: request.toJson());
      debugPrint('[AuthRepository] login succeeded');
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[AuthRepository] login error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResponse> validateToken(TokenValidationRequest request) async {
    debugPrint('[AuthRepository] validateToken called');
    try {
      final response = await _dio.post('/validate', data: request.toJson());
      debugPrint('[AuthRepository] validateToken succeeded');
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[AuthRepository] validateToken error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout(LogoutRequest request) async {
    debugPrint('[AuthRepository] logout called for userId: ${request.token}');
    try {
      await _dio.post('/logout', data: request.toJson());
      debugPrint('[AuthRepository] logout succeeded');
    } on DioException catch (e) {
      debugPrint('[AuthRepository] logout error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> healthCheck() async {
    debugPrint('[AuthRepository] healthCheck called');
    try {
      final response = await _dio.get('/health');
      debugPrint('[AuthRepository] healthCheck succeeded');
      return response.data as String;
    } on DioException catch (e) {
      debugPrint('[AuthRepository] healthCheck error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    debugPrint(
      '[AuthRepository] Dio error: ${e.message}, status: ${e.response?.statusCode}',
    );
    return Exception('Network error: ${e.message}');
  }
}
