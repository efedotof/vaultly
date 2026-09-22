import 'dart:async';

import 'package:vaulth_app/server/model/device/device_register_request/device_register_request.dart';
import 'package:vaulth_app/server/model/device/device_response/device_response.dart';
import 'package:vaulth_app/server/model/device/device_update_request/device_update_request.dart';

abstract class DeviceInterface {
  Future<DeviceResponse> registerDevice(DeviceRegisterRequest request);
  Future<List<DeviceResponse>> getUserDevices();
  Future<String> getEncryptedPrivateKey(String deviceId);
  Future<DeviceResponse> updateDevice(
    String deviceId,
    DeviceUpdateRequest request,
  );
  Future<void> deactivateDevice(String deviceId);
  Future<void> deleteDevice(String deviceId);
}
