// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceRegisterRequest _$DeviceRegisterRequestFromJson(
  Map<String, dynamic> json,
) => _DeviceRegisterRequest(
  deviceName: json['deviceName'] as String,
  deviceType: json['deviceType'] as String,
  uniqueId: json['uniqueId'] as String,
  publicKey: json['publicKey'] as String,
  encryptedPrivateKey: json['encryptedPrivateKey'] as String,
);

Map<String, dynamic> _$DeviceRegisterRequestToJson(
  _DeviceRegisterRequest instance,
) => <String, dynamic>{
  'deviceName': instance.deviceName,
  'deviceType': instance.deviceType,
  'uniqueId': instance.uniqueId,
  'publicKey': instance.publicKey,
  'encryptedPrivateKey': instance.encryptedPrivateKey,
};
