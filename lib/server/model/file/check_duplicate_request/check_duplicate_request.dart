import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_duplicate_request.freezed.dart';
part 'check_duplicate_request.g.dart';

@freezed
abstract class CheckDuplicateRequest with _$CheckDuplicateRequest {
  const factory CheckDuplicateRequest({
    required String hash,
    required bool isPublic,
  }) = _CheckDuplicateRequest;

  factory CheckDuplicateRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckDuplicateRequestFromJson(json);
}
