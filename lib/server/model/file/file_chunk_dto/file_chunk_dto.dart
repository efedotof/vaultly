import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:typed_data';

import 'package:vaulth_app/server/model/file/file_upload_request/uint8_list_converter.dart';

part 'file_chunk_dto.freezed.dart';
part 'file_chunk_dto.g.dart';

@freezed
abstract class FileChunkDto with _$FileChunkDto {
  const factory FileChunkDto({
    required String fileName,
    required String contentType,
    @Uint8ListConverter() Uint8List? data,
    required bool lastChunk,
    String? folderId,
  }) = _FileChunkDto;

  factory FileChunkDto.fromJson(Map<String, dynamic> json) =>
      _$FileChunkDtoFromJson(json);
}
