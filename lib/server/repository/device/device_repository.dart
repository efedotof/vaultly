import 'package:get/get_connect.dart';
import 'package:vaulth_app/server/model/device/device_register_request.dart';
import 'package:vaulth_app/server/model/device/device_response.dart';
import 'package:vaulth_app/server/model/device/device_update_request.dart';
import 'package:vaulth_app/server/repository/device/device_interface.dart';

class DeviceRepository extends GetConnect implements DeviceInterface {
  
  @override
  //PostMapping
  Future<void> deactivateDevice({required String deviceId}) {
    // TODO: implement deactivateDevice
    throw UnimplementedError();
  }

  @override
  //DeleteMapping
  Future<void> deleteDevice({required String deviceId}) {
    // TODO: implement deleteDevice
    throw UnimplementedError();
  }

  @override
  //GetMapping
  Future<List<DeviceResponse>> getUserDevices() {
    // TODO: implement getUserDevices
    throw UnimplementedError();
  }

  @override
  //PostMapping
  Future<DeviceResponse> registerDevice({required DeviceRegisterRequest request}) {
    // TODO: implement registerDevice
    throw UnimplementedError();
  }

  @override
  //PutMapping
  Future<DeviceResponse> updateDevice({required DeviceUpdateRequest request, required String deviceId}) {
    // TODO: implement updateDevice
    throw UnimplementedError();
  }
}
