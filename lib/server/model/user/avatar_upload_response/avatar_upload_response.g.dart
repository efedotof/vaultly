// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avatar_upload_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AvatarUploadResponse _$AvatarUploadResponseFromJson(
  Map<String, dynamic> json,
) => _AvatarUploadResponse(
  avatarUrl: json['avatarUrl'] as String?,
  fileSize: (json['fileSize'] as num?)?.toInt(),
);

Map<String, dynamic> _$AvatarUploadResponseToJson(
  _AvatarUploadResponse instance,
) => <String, dynamic>{
  'avatarUrl': instance.avatarUrl,
  'fileSize': instance.fileSize,
};
