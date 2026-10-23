import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/api_client.dart';
import 'package:vaulth_app/server/exception/auth_error_exception.dart';
import 'package:vaulth_app/server/exception/not_found_exception.dart';
import 'package:vaulth_app/server/exception/rate_limit_exception.dart';
import 'package:vaulth_app/server/exception/unknown_error_exception.dart';
import 'package:vaulth_app/server/exception/validation_error_exception.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

import 'device_interface.dart';
import 'package:vaulth_app/server/model/device/device_register_request.dart';
import 'package:vaulth_app/server/model/device/device_response.dart';
import 'package:vaulth_app/server/model/device/device_update_request.dart';

class DeviceRepository implements DeviceInterface {
  final ApiClient _apiClient;
  final Config _config;

  DeviceRepository({required ApiClient apiClient, required Config config})
    : _apiClient = apiClient,
      _config = config;

  @override //post
  Future<DeviceResponse> registerDevice({
    required DeviceRegisterRequest request,
  }) async {
    try {
      final resp = await _apiClient.post(
        '${_config.deviceUrl}/register',
        request.toJson(),
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return DeviceResponse.fromJson(resp.body);

        case 400:
          throw ValidationErrorException("Неправильный формат!");
        case 401:
          throw AuthErrorException();
        case 403:
          throw AuthErrorException(
            "Устройство уже зарегистрировано другим пользователем",
          );
        case 429:
          throw RateLimitException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "DeviceRepository: registerDevice");
      throw UnknownErrorException();
    }
  }

  @override //get
  Future<List<DeviceResponse>> getUserDevices() async {
    try {
      final resp = await _apiClient.get('${_config.deviceUrl}/me-device');

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null) throw UnknownErrorException();
          return (resp.body as List)
              .map((e) => DeviceResponse.fromJson(e as Map<String, dynamic>))
              .toList();

        case 401:
          throw AuthErrorException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "DeviceRepository: getUserDevices");
      throw UnknownErrorException();
    }
  }

  @override //put
  Future<DeviceResponse> updateDevice({
    required DeviceUpdateRequest request,
    required String deviceId,
  }) async {
    try {
      final resp = await _apiClient.put(
        '${_config.deviceUrl}/$deviceId',
        request.toJson(),
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return DeviceResponse.fromJson(resp.body);

        case 400:
          throw ValidationErrorException("Неправильный формат!");
        case 401:
          throw AuthErrorException();
        case 404:
          throw NotFoundException("Устройство не найдено");
        case 429:
          throw RateLimitException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "DeviceRepository: updateDevice");
      throw UnknownErrorException();
    }
  }

  @override //post
  Future<void> deactivateDevice({required String deviceId}) async {
    try {
      final resp = await _apiClient.post(
        '${_config.deviceUrl}/$deviceId/deactivate',
        {},
      );

      switch (resp.statusCode) {
        case 200:
          return;

        case 400:
          throw ValidationErrorException("Неправильный формат!");
        case 401:
          throw AuthErrorException();
        case 404:
          throw NotFoundException("Устройство не найдено");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "DeviceRepository: deactivateDevice");
      throw UnknownErrorException();
    }
  }

  @override //delete
  Future<void> deleteDevice({required String deviceId}) async {
    try {
      final resp = await _apiClient.delete('${_config.deviceUrl}/$deviceId');

      switch (resp.statusCode) {
        case 200:
          return;

        case 400:
          throw ValidationErrorException("Неправильный формат!");
        case 401:
          throw AuthErrorException();
        case 404:
          throw NotFoundException("Устройство не найдено");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "DeviceRepository: deleteDevice");
      throw UnknownErrorException();
    }
  }
}
