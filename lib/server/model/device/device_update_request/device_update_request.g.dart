// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceUpdateRequest _$DeviceUpdateRequestFromJson(Map<String, dynamic> json) =>
    _DeviceUpdateRequest(
      deviceName: json['deviceName'] as String?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$DeviceUpdateRequestToJson(
  _DeviceUpdateRequest instance,
) => <String, dynamic>{
  'deviceName': instance.deviceName,
  'isActive': instance.isActive,
};
