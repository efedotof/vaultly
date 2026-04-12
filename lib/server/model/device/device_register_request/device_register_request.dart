import 'package:freezed_annotation/freezed_annotation.dart';
part 'device_register_request.freezed.dart';
part 'device_register_request.g.dart';

@freezed
abstract class DeviceRegisterRequest with _$DeviceRegisterRequest {
  const factory DeviceRegisterRequest({
    required String deviceName,
    required String deviceType,
    required String uniqueId,
    required String publicKey,
    required String encryptedPrivateKey,
  }) = _DeviceRegisterRequest;

  factory DeviceRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$DeviceRegisterRequestFromJson(json);
}
