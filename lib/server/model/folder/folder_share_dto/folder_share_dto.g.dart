// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_share_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FolderShareDto _$FolderShareDtoFromJson(Map<String, dynamic> json) =>
    _FolderShareDto(
      folderId: json['folderId'] as String?,
      userIds: (json['userIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      canEdit: json['canEdit'] as bool?,
      canDelete: json['canDelete'] as bool?,
      canShare: json['canShare'] as bool?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$FolderShareDtoToJson(_FolderShareDto instance) =>
    <String, dynamic>{
      'folderId': instance.folderId,
      'userIds': instance.userIds,
      'canEdit': instance.canEdit,
      'canDelete': instance.canDelete,
      'canShare': instance.canShare,
      'message': instance.message,
    };
