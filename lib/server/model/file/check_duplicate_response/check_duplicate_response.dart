import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_duplicate_response.freezed.dart';
part 'check_duplicate_response.g.dart';

@freezed
abstract class CheckDuplicateResponse with _$CheckDuplicateResponse {
  const factory CheckDuplicateResponse({
    required bool exists,
    String? fileContentId,
  }) = _CheckDuplicateResponse;

  factory CheckDuplicateResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckDuplicateResponseFromJson(json);
}
