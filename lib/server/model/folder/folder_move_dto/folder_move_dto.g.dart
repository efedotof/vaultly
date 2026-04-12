// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_move_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FolderMoveDto _$FolderMoveDtoFromJson(Map<String, dynamic> json) =>
    _FolderMoveDto(
      fileIds: (json['fileIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      targetFolderId: json['targetFolderId'] as String?,
      sourceFolderId: json['sourceFolderId'] as String?,
      copy: json['copy'] as bool?,
    );

Map<String, dynamic> _$FolderMoveDtoToJson(_FolderMoveDto instance) =>
    <String, dynamic>{
      'fileIds': instance.fileIds,
      'targetFolderId': instance.targetFolderId,
      'sourceFolderId': instance.sourceFolderId,
      'copy': instance.copy,
    };
