// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_chunk_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FileChunkDto _$FileChunkDtoFromJson(Map<String, dynamic> json) =>
    _FileChunkDto(
      fileName: json['fileName'] as String,
      contentType: json['contentType'] as String,
      data: const Uint8ListConverter().fromJson(json['data'] as String?),
      lastChunk: json['lastChunk'] as bool,
      folderId: json['folderId'] as String?,
    );

Map<String, dynamic> _$FileChunkDtoToJson(_FileChunkDto instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'contentType': instance.contentType,
      'data': const Uint8ListConverter().toJson(instance.data),
      'lastChunk': instance.lastChunk,
      'folderId': instance.folderId,
    };
