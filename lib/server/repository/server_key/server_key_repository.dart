import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
            debugPrint(
              '[FileRepository] ✅ Токен установлен для ${options.uri}',
            );
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            debugPrint(
              '[FileRepository] ⚠️ Токен отсутствует для ${options.uri}',
            );
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
      debugPrint(
        '[ServerKeyRepository] Failed to parse public key from PEM: $e',
      );
      throw Exception('Invalid server public key format');
    }
  }

  @override
  Future<String> getServerPublicKeyPem() async {
    debugPrint('[ServerKeyRepository] Fetching server public key...');
    try {
      final response = await _dio.get('/public');
      final pem = response.data as String;
      debugPrint(
        '[ServerKeyRepository] Server public key received, length: ${pem.length}',
      );
      return pem;
    } on DioException catch (e) {
      debugPrint(
        '[ServerKeyRepository] Failed to fetch server public key: ${e.message}',
      );
      throw Exception('Could not retrieve server public key: ${e.message}');
    }
  }
}
