import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:vaulth_app/storage/auth_local_storage.dart';
import 'user_interface.dart';
import 'package:vaulth_app/server/model/user/update_user_request/update_user_request.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto/user_profile_dto.dart';

class UserRepository implements UserInterface {
  final Dio _dio;
  final String userAddress;
  final AuthLocalStorage authLocalStorage;

  UserRepository({required this.userAddress, required this.authLocalStorage})
    : _dio = Dio(
        BaseOptions(
          baseUrl: userAddress,
          connectTimeout: const Duration(seconds: 40),
          receiveTimeout: const Duration(seconds: 40),
        ),
      ) {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await authLocalStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            debugPrint(
              '[UserRepository] ✅ Токен установлен для ${options.uri}',
            );
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            debugPrint(
              '[UserRepository] ⚠️ Токен отсутствует для ${options.uri}',
            );
          }
          return handler.next(options);
        },
      ),
    );
  }

  @override
  Future<UserProfileDto> getCurrentUserProfile() async {
    debugPrint('[UserRepository] getCurrentUserProfile called');
    try {
      final response = await _dio.get('/me');
      debugPrint('[UserRepository] getCurrentUserProfile succeeded');
      return UserProfileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[UserRepository] getCurrentUserProfile error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserProfileDto> updateCurrentUser(UpdateUserRequest request) async {
    debugPrint(
      '[UserRepository] updateCurrentUser called: name=${request.username}, firstName=${request.firstName}',
    );
    try {
      final response = await _dio.put('/me', data: request.toJson());
      debugPrint('[UserRepository] updateCurrentUser succeeded');
      return UserProfileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[UserRepository] updateCurrentUser error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserProfileDto> getUserProfileById(String id) async {
    debugPrint('[UserRepository] getUserProfileById called: id=$id');
    try {
      final response = await _dio.get('/$id');
      debugPrint('[UserRepository] getUserProfileById succeeded');
      return UserProfileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[UserRepository] getUserProfileById error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    debugPrint(
      '[UserRepository] Dio error: ${e.message}, status: ${e.response?.statusCode}',
    );
    return Exception('Network error: ${e.message}');
  }

  @override
  Future<String> getUserEncryptedPrivateKey() async {
    final response = await _dio.get('/me/private-key-encrypted');
    return response.data as String;
  }

  @override
  Future<String> getUserSalt() async {
    final response = await _dio.get('/me/salt');
    return response.data as String;
  }
}
