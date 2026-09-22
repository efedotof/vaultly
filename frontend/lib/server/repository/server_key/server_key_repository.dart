import 'package:dio/dio.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';
import 'server_key_interface.dart';

class ServerKeyRepository implements ServerKeyInterface {
  final Dio _dio;
  final String baseUrl;
  final AuthLocalStorage authLocalStorage;
  ServerKeyRepository({required this.baseUrl, required this.authLocalStorage})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
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
  Future<RSAPublicKey> getServerPublicKey() async {
    final pem = await getServerPublicKeyPem();
    try {
      return CryptoUtils.rsaPublicKeyFromPem(pem);
    } catch (e) {
      throw Exception('Invalid server public key format');
    }
  }

  @override
  Future<String> getServerPublicKeyPem() async {
    try {
      final response = await _dio.get('/public');
      final pem = response.data as String;
      return pem;
    } on DioException catch (e) {
      throw Exception('Could not retrieve server public key: ${e.message}');
    }
  }
}
