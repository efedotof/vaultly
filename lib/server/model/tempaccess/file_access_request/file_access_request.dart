import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_access_request.freezed.dart';
part 'file_access_request.g.dart';

@freezed
abstract class FileAccessRequest with _$FileAccessRequest {
  const factory FileAccessRequest({
    bool? isPublic,
  }) = _FileAccessRequest;

  factory FileAccessRequest.fromJson(Map<String, dynamic> json) =>
      _$FileAccessRequestFromJson(json);
}