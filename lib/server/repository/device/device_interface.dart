import 'package:vaulth_app/server/model/device/device_register_request.dart';
import 'package:vaulth_app/server/model/device/device_response.dart';
import 'package:vaulth_app/server/model/device/device_update_request.dart';

abstract interface class DeviceInterface {
  //регистрация устройства
  Future<DeviceResponse> registerDevice({required DeviceRegisterRequest request});

  //получение устройств пользователей
  Future<List<DeviceResponse>> getUserDevices();

  //обновить информации устройств пользователей
  Future<DeviceResponse> updateDevice({required DeviceUpdateRequest request,required String  deviceId});

  //деактивировать устройство
  Future<void> deactivateDevice({required String deviceId});
  
  //удалить устройство
  Future<void> deleteDevice({required String deviceId});
}

