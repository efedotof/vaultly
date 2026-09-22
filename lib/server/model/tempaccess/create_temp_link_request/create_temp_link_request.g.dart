// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_temp_link_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateTempLinkRequest _$CreateTempLinkRequestFromJson(
  Map<String, dynamic> json,
) => _CreateTempLinkRequest(
  fileId: json['fileId'] as String,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  maxDownloads: (json['maxDownloads'] as num?)?.toInt(),
  password: json['password'] as String?,
);

Map<String, dynamic> _$CreateTempLinkRequestToJson(
  _CreateTempLinkRequest instance,
) => <String, dynamic>{
  'fileId': instance.fileId,
  'expiresAt': instance.expiresAt.toIso8601String(),
  'maxDownloads': instance.maxDownloads,
  'password': instance.password,
};
