import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_type/folder_type.dart';

part 'folder_dto.freezed.dart';
part 'folder_dto.g.dart';

@freezed
abstract class FolderDto with _$FolderDto {
  const factory FolderDto({
    required String? id,
    required String? name,
    required String? path,
    required FolderType? type,
    required bool? isHidden,
    required bool? isLocked,
    required String? allowedUsers,
    required DateTime? createdAt,
    required DateTime? updatedAt,
    String? parentFolderId,
    String? parentFolderName,
    @Default([]) List<FolderDto>? subfolders,
    @Default([]) List<FileDto>? files,
  }) = _FolderDto;

  factory FolderDto.fromJson(Map<String, dynamic> json) =>
      _$FolderDtoFromJson(json);
}
