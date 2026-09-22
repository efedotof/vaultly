import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder_update_dto.freezed.dart';
part 'folder_update_dto.g.dart';

@freezed
abstract class FolderUpdateDto with _$FolderUpdateDto {
  const factory FolderUpdateDto({
    String? name,
    String? description,
    bool? isHidden,
  }) = _FolderUpdateDto;

  factory FolderUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$FolderUpdateDtoFromJson(json);
}
