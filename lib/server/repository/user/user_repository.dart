import 'package:dio/dio.dart';
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
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  @override
  Future<UserProfileDto> getCurrentUserProfile() async {
    try {
      final response = await _dio.get('/me');
      return UserProfileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserProfileDto> updateCurrentUser(UpdateUserRequest request) async {
    try {
      final response = await _dio.put('/me', data: request.toJson());
      return UserProfileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserProfileDto> getUserProfileById(String id) async {
    try {
      final response = await _dio.get('/$id');
      return UserProfileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
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
