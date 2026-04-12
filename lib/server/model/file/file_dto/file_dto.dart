import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_dto.freezed.dart';
part 'file_dto.g.dart';

@freezed
abstract class FileDto with _$FileDto {
  const factory FileDto({
    String? id,
    required String name,
    required String originalName,
    required int size,
    required String mimeType,
    String? s3Url,
    bool? isEncrypted,
    bool? isPublic,
    @JsonKey(name: 'createdAt') DateTime? createdAt,
    String? folderId,
    String? folderName,
  }) = _FileDto;

  factory FileDto.fromJson(Map<String, dynamic> json) =>
      _$FileDtoFromJson(json);
}
