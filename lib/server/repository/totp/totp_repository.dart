import 'package:dio/dio.dart';
import 'package:vaulth_app/server/model/totp/totp_disable_request/totp_disable_request.dart';
import 'package:vaulth_app/server/model/totp/totp_setup_response/totp_setup_response.dart';
import 'package:vaulth_app/server/model/totp/totp_verify_request/totp_verify_request.dart';
import 'package:vaulth_app/server/model/totp/totp_verify_response/totp_verify_response.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

import 'totp_interface.dart';

class TotpRepository implements TotpInterface {
  final Dio _dio;
  final String totpAddress;
  final AuthLocalStorage authLocalStorage;

  TotpRepository({required this.totpAddress, required this.authLocalStorage})
    : _dio = Dio(
        BaseOptions(
          baseUrl: totpAddress,
          connectTimeout: const Duration(seconds: 3000),
          receiveTimeout: const Duration(seconds: 3000),
        ),
      ) {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await authLocalStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  @override
  Future<TotpSetupResponse> setupTotp() async {
    try {
      final response = await _dio.post('/totp/setup');
      return TotpSetupResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TotpVerifyResponse> verifyTotp(TotpVerifyRequest request) async {
    try {
      final response = await _dio.post('/totp/verify', data: request.toJson());
      return TotpVerifyResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> disableTotp(TotpDisableRequest request) async {
    try {
      await _dio.post('/totp/disable', data: request.toJson());
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    final message = e.response?.data?['message'] ?? e.message;
    return Exception('Network error: $message');
  }
}
