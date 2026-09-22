import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder_move_dto.freezed.dart';
part 'folder_move_dto.g.dart';

@freezed
abstract class FolderMoveDto with _$FolderMoveDto {
  const factory FolderMoveDto({
    List<String>? fileIds,
    String? targetFolderId,
    String? sourceFolderId,
    bool? copy,
  }) = _FolderMoveDto;

  factory FolderMoveDto.fromJson(Map<String, dynamic> json) =>
      _$FolderMoveDtoFromJson(json);
}
