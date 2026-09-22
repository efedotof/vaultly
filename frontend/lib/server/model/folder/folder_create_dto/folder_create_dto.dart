import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder_create_dto.freezed.dart';
part 'folder_create_dto.g.dart';

@freezed
abstract class FolderCreateDto with _$FolderCreateDto {
  const factory FolderCreateDto({
    required String name,
    String? parentFolderId,
    bool? isHidden,
    String? hiddenFolderKey,
    bool? isPrivate,
    String? password,
    String? description,
  }) = _FolderCreateDto;

  factory FolderCreateDto.fromJson(Map<String, dynamic> json) =>
      _$FolderCreateDtoFromJson(json);
}