import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
            debugPrint('[DeviceRepository] Token установлен: $token');
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            debugPrint('[DeviceRepository] Токен отсутствует');
          }
          return handler.next(options);
        },
      ),
    );
  }

  @override
  Future<DeviceResponse> registerDevice(DeviceRegisterRequest request) async {
    debugPrint(
      '[DeviceRepository] registerDevice called for device: ${request.deviceName}',
    );
    try {
      final response = await _dio.post('/register', data: request.toJson());
      debugPrint('[DeviceRepository] registerDevice succeeded');
      return DeviceResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[DeviceRepository] registerDevice error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<DeviceResponse>> getUserDevices() async {
    debugPrint('[DeviceRepository] getUserDevices called');
    try {
      final response = await _dio.get('/me-device');
      debugPrint(
        '[DeviceRepository] getUserDevices succeeded, count: ${(response.data as List).length}',
      );
      final list = response.data as List;
      return list
          .map((item) => DeviceResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[DeviceRepository] getUserDevices error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> getEncryptedPrivateKey(String deviceId) async {
    debugPrint(
      '[DeviceRepository] getEncryptedPrivateKey called for deviceId: $deviceId',
    );
    try {
      final response = await _dio.get('/$deviceId/key');
      debugPrint('[DeviceRepository] getEncryptedPrivateKey succeeded');
      return response.data as String;
    } on DioException catch (e) {
      debugPrint(
        '[DeviceRepository] getEncryptedPrivateKey error: ${e.message}',
      );
      throw _handleDioError(e);
    }
  }

  @override
  Future<DeviceResponse> updateDevice(
    String deviceId,
    DeviceUpdateRequest request,
  ) async {
    debugPrint(
      '[DeviceRepository] updateDevice called for deviceId: $deviceId',
    );
    try {
      final response = await _dio.put('/$deviceId', data: request.toJson());
      debugPrint('[DeviceRepository] updateDevice succeeded');
      return DeviceResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[DeviceRepository] updateDevice error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deactivateDevice(String deviceId) async {
    debugPrint(
      '[DeviceRepository] deactivateDevice called for deviceId: $deviceId',
    );
    try {
      await _dio.post('/$deviceId/deactivate');
      debugPrint('[DeviceRepository] deactivateDevice succeeded');
    } on DioException catch (e) {
      debugPrint('[DeviceRepository] deactivateDevice error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    debugPrint(
      '[DeviceRepository] deleteDevice called for deviceId: $deviceId',
    );
    try {
      await _dio.delete('/$deviceId');
      debugPrint('[DeviceRepository] deleteDevice succeeded');
    } on DioException catch (e) {
      debugPrint('[DeviceRepository] deleteDevice error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    debugPrint(
      '[DeviceRepository] Dio error: ${e.message}, status: ${e.response?.statusCode}',
    );
    return Exception('Network error: ${e.message}');
  }
}
