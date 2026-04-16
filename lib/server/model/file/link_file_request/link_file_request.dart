import 'package:freezed_annotation/freezed_annotation.dart';

part 'link_file_request.freezed.dart';
part 'link_file_request.g.dart';

@freezed
abstract class LinkFileRequest with _$LinkFileRequest {
  const factory LinkFileRequest({
    required String fileContentId,
    required String fileName,
    String? folderId,
    required bool isPublic,
  }) = _LinkFileRequest;

  factory LinkFileRequest.fromJson(Map<String, dynamic> json) =>
      _$LinkFileRequestFromJson(json);
}
