import 'package:freezed_annotation/freezed_annotation.dart';

part 'avatar_upload_response.freezed.dart';
part 'avatar_upload_response.g.dart';

@freezed
abstract class AvatarUploadResponse with _$AvatarUploadResponse {
  const factory AvatarUploadResponse({
    String? avatarUrl,
    int? fileSize,
  }) = _AvatarUploadResponse;

  factory AvatarUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$AvatarUploadResponseFromJson(json);
}