import 'package:freezed_annotation/freezed_annotation.dart';
part 'device_response.freezed.dart';
part 'device_response.g.dart';

@freezed
abstract class DeviceResponse with _$DeviceResponse {
  const factory DeviceResponse({
    String? id,
    String? deviceName,
    String? deviceType,
    String? uniqueId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) = _DeviceResponse;

  factory DeviceResponse.fromJson(Map<String, dynamic> json) =>
      _$DeviceResponseFromJson(json);
}
