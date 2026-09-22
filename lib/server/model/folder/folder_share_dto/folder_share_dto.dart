import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder_share_dto.freezed.dart';
part 'folder_share_dto.g.dart';

@freezed
abstract class FolderShareDto with _$FolderShareDto {
  const factory FolderShareDto({
    String? folderId,
    List<String>? userIds,
    bool? canEdit,
    bool? canDelete,
    bool? canShare,
    String? message,
  }) = _FolderShareDto;

  factory FolderShareDto.fromJson(Map<String, dynamic> json) =>
      _$FolderShareDtoFromJson(json);
}