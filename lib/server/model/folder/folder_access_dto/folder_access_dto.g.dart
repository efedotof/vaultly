// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_access_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FolderAccessDto _$FolderAccessDtoFromJson(Map<String, dynamic> json) =>
    _FolderAccessDto(
      folderId: json['folderId'] as String?,
      password: json['password'] as String?,
      hiddenFolderKey: json['hiddenFolderKey'] as String?,
    );

Map<String, dynamic> _$FolderAccessDtoToJson(_FolderAccessDto instance) =>
    <String, dynamic>{
      'folderId': instance.folderId,
      'password': instance.password,
      'hiddenFolderKey': instance.hiddenFolderKey,
    };
