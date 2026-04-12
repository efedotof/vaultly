// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceResponse _$DeviceResponseFromJson(Map<String, dynamic> json) =>
    _DeviceResponse(
      id: json['id'] as String?,
      deviceName: json['deviceName'] as String?,
      deviceType: json['deviceType'] as String?,
      uniqueId: json['uniqueId'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] == null
          ? null
          : DateTime.parse(json['lastUsedAt'] as String),
    );

Map<String, dynamic> _$DeviceResponseToJson(_DeviceResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceName': instance.deviceName,
      'deviceType': instance.deviceType,
      'uniqueId': instance.uniqueId,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
      'lastUsedAt': instance.lastUsedAt?.toIso8601String(),
    };
