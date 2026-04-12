import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_move_request.freezed.dart';
part 'file_move_request.g.dart';

@freezed
abstract class FileMoveRequest with _$FileMoveRequest {
  const factory FileMoveRequest({
    int? targetFolderId,
  }) = _FileMoveRequest;

  factory FileMoveRequest.fromJson(Map<String, dynamic> json) =>
      _$FileMoveRequestFromJson(json);
}