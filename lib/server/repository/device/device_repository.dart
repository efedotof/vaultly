import 'package:dio/dio.dart';
import 'package:vaulth_app/server/model/device/device_register_request/device_register_request.dart';
import 'package:vaulth_app/server/model/device/device_response/device_response.dart';
import 'package:vaulth_app/server/model/device/device_update_request/device_update_request.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';
import 'device_interface.dart';

class DeviceRepository implements DeviceInterface {
  final Dio _dio;
  final String deviceAddress;
  final AuthLocalStorage authLocalStorage;

  DeviceRepository({
    required this.deviceAddress,
    required this.authLocalStorage,
    getUserDevices,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: deviceAddress,
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
  Future<DeviceResponse> registerDevice(DeviceRegisterRequest request) async {
    try {
      final response = await _dio.post('/register', data: request.toJson());
      return DeviceResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<DeviceResponse>> getUserDevices() async {
    try {
      final response = await _dio.get('/me-device');
      final list = response.data as List;
      return list
          .map((item) => DeviceResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> getEncryptedPrivateKey(String deviceId) async {
    try {
      final response = await _dio.get('/$deviceId/key');
      return response.data as String;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<DeviceResponse> updateDevice(
    String deviceId,
    DeviceUpdateRequest request,
  ) async {
    try {
      final response = await _dio.put('/$deviceId', data: request.toJson());
      return DeviceResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deactivateDevice(String deviceId) async {
    try {
      await _dio.post('/$deviceId/deactivate');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    try {
      await _dio.delete('/$deviceId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    return Exception('Network error: ${e.message}');
  }
}
