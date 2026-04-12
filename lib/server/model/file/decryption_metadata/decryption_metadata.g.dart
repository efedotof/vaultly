// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decryption_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DecryptionMetadata _$DecryptionMetadataFromJson(Map<String, dynamic> json) =>
    _DecryptionMetadata(
      presignedUrl: json['presignedUrl'] as String,
      encryptedKey: json['encryptedKey'] as String,
      iv: json['iv'] as String,
      originalSize: (json['originalSize'] as num).toInt(),
      mimeType: json['mimeType'] as String,
      fileName: json['fileName'] as String,
    );

Map<String, dynamic> _$DecryptionMetadataToJson(_DecryptionMetadata instance) =>
    <String, dynamic>{
      'presignedUrl': instance.presignedUrl,
      'encryptedKey': instance.encryptedKey,
      'iv': instance.iv,
      'originalSize': instance.originalSize,
      'mimeType': instance.mimeType,
      'fileName': instance.fileName,
    };
