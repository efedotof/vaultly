import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_temp_link_request.freezed.dart';
part 'create_temp_link_request.g.dart';

@freezed
abstract class CreateTempLinkRequest with _$CreateTempLinkRequest {
  const factory CreateTempLinkRequest({
    required String fileId,
    required DateTime expiresAt,
    int? maxDownloads,
    String? password,
  }) = _CreateTempLinkRequest;

  factory CreateTempLinkRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTempLinkRequestFromJson(json);
}
