// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_create_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FolderCreateDto _$FolderCreateDtoFromJson(Map<String, dynamic> json) =>
    _FolderCreateDto(
      name: json['name'] as String,
      parentFolderId: json['parentFolderId'] as String?,
      isHidden: json['isHidden'] as bool?,
      hiddenFolderKey: json['hiddenFolderKey'] as String?,
      isPrivate: json['isPrivate'] as bool?,
      password: json['password'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$FolderCreateDtoToJson(_FolderCreateDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'parentFolderId': instance.parentFolderId,
      'isHidden': instance.isHidden,
      'hiddenFolderKey': instance.hiddenFolderKey,
      'isPrivate': instance.isPrivate,
      'password': instance.password,
      'description': instance.description,
    };
