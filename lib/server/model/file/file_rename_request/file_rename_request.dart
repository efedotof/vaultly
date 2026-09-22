import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_rename_request.freezed.dart';
part 'file_rename_request.g.dart';

@freezed
abstract class FileRenameRequest with _$FileRenameRequest {
  const factory FileRenameRequest({
    required String newName,
  }) = _FileRenameRequest;

  factory FileRenameRequest.fromJson(Map<String, dynamic> json) =>
      _$FileRenameRequestFromJson(json);
}