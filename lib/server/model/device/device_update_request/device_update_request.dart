import 'package:freezed_annotation/freezed_annotation.dart';
part 'device_update_request.freezed.dart';
part 'device_update_request.g.dart';

@freezed
abstract class DeviceUpdateRequest with _$DeviceUpdateRequest {
  const factory DeviceUpdateRequest({String? deviceName, bool? isActive}) =
      _DeviceUpdateRequest;

  factory DeviceUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$DeviceUpdateRequestFromJson(json);
}
