import 'package:freezed_annotation/freezed_annotation.dart';

part 'temp_link_response.freezed.dart';
part 'temp_link_response.g.dart';

@freezed
abstract class TempLinkResponse with _$TempLinkResponse {
  const factory TempLinkResponse({
    required String token,
    required String accessUrl,
    required DateTime expiresAt,
    int? maxDownloads,
    required int downloadsCount,
  }) = _TempLinkResponse;

  factory TempLinkResponse.fromJson(Map<String, dynamic> json) =>
      _$TempLinkResponseFromJson(json);
}
