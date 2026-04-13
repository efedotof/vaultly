import 'package:dio/dio.dart';
import 'package:vaulth_app/server/model/tempaccess/create_temp_link_request/create_temp_link_request.dart';
import 'package:vaulth_app/server/model/tempaccess/temp_link_response/temp_link_response.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';
import 'temp_access_interface.dart';

class TempAccessRepository implements TempAccessInterface {
  final Dio _dio;
  final AuthLocalStorage authLocalStorage;

  TempAccessRepository({
    required String baseUrl,
    required this.authLocalStorage,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
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
  Future<TempLinkResponse> createTempLink(CreateTempLinkRequest request) async {
    try {
      final response = await _dio.post(
        '/temp-access/create',
        data: request.toJson(),
      );
      return TempLinkResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    final msg = e.response?.data?['message'] ?? e.message;
    return Exception('Ошибка создания временной ссылки: $msg');
  }
}
