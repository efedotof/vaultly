// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FileDto _$FileDtoFromJson(Map<String, dynamic> json) => _FileDto(
  id: json['id'] as String?,
  name: json['name'] as String,
  originalName: json['originalName'] as String,
  size: (json['size'] as num).toInt(),
  mimeType: json['mimeType'] as String,
  s3Url: json['s3Url'] as String?,
  isEncrypted: json['isEncrypted'] as bool?,
  isPublic: json['isPublic'] as bool?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  folderId: json['folderId'] as String?,
  folderName: json['folderName'] as String?,
);

Map<String, dynamic> _$FileDtoToJson(_FileDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'originalName': instance.originalName,
  'size': instance.size,
  'mimeType': instance.mimeType,
  's3Url': instance.s3Url,
  'isEncrypted': instance.isEncrypted,
  'isPublic': instance.isPublic,
  'createdAt': instance.createdAt?.toIso8601String(),
  'folderId': instance.folderId,
  'folderName': instance.folderName,
};
