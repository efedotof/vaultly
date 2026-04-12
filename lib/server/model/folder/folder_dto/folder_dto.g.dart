// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FolderDto _$FolderDtoFromJson(Map<String, dynamic> json) => _FolderDto(
  id: json['id'] as String?,
  name: json['name'] as String?,
  path: json['path'] as String?,
  type: $enumDecodeNullable(_$FolderTypeEnumMap, json['type']),
  isHidden: json['isHidden'] as bool?,
  isLocked: json['isLocked'] as bool?,
  allowedUsers: json['allowedUsers'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  parentFolderId: json['parentFolderId'] as String?,
  parentFolderName: json['parentFolderName'] as String?,
  subfolders:
      (json['subfolders'] as List<dynamic>?)
          ?.map((e) => FolderDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  files:
      (json['files'] as List<dynamic>?)
          ?.map((e) => FileDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$FolderDtoToJson(_FolderDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'path': instance.path,
      'type': _$FolderTypeEnumMap[instance.type],
      'isHidden': instance.isHidden,
      'isLocked': instance.isLocked,
      'allowedUsers': instance.allowedUsers,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'parentFolderId': instance.parentFolderId,
      'parentFolderName': instance.parentFolderName,
      'subfolders': instance.subfolders,
      'files': instance.files,
    };

const _$FolderTypeEnumMap = {
  FolderType.def: 'DEFAULT',
  FolderType.systemRecentlyDeleted: 'SYSTEM_RECENTLY_DELETED',
  FolderType.systemTempLinks: 'SYSTEM_TEMP_LINKS',
  FolderType.systemRoot: 'SYSTEM_ROOT',
  FolderType.systemHidden: 'SYSTEM_HIDDEN',
  FolderType.custom: 'CUSTOM',
};
