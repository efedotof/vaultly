// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'temp_link_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TempLinkResponse _$TempLinkResponseFromJson(Map<String, dynamic> json) =>
    _TempLinkResponse(
      token: json['token'] as String,
      accessUrl: json['accessUrl'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      maxDownloads: (json['maxDownloads'] as num?)?.toInt(),
      downloadsCount: (json['downloadsCount'] as num).toInt(),
    );

Map<String, dynamic> _$TempLinkResponseToJson(_TempLinkResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'accessUrl': instance.accessUrl,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'maxDownloads': instance.maxDownloads,
      'downloadsCount': instance.downloadsCount,
    };
