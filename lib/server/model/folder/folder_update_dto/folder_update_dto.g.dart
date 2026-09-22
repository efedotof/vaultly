// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_update_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FolderUpdateDto _$FolderUpdateDtoFromJson(Map<String, dynamic> json) =>
    _FolderUpdateDto(
      name: json['name'] as String?,
      description: json['description'] as String?,
      isHidden: json['isHidden'] as bool?,
    );

Map<String, dynamic> _$FolderUpdateDtoToJson(_FolderUpdateDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'isHidden': instance.isHidden,
    };
