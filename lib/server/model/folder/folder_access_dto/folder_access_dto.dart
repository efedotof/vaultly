import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder_access_dto.freezed.dart';
part 'folder_access_dto.g.dart';

@freezed
abstract class FolderAccessDto with _$FolderAccessDto {
  const factory FolderAccessDto({
    String? folderId,
    String? password,
    String? hiddenFolderKey,
  }) = _FolderAccessDto;

  factory FolderAccessDto.fromJson(Map<String, dynamic> json) =>
      _$FolderAccessDtoFromJson(json);
}