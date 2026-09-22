import 'package:freezed_annotation/freezed_annotation.dart';

part 'totp_verify_response.freezed.dart';
part 'totp_verify_response.g.dart';

@freezed
abstract class TotpVerifyResponse with _$TotpVerifyResponse {
  const factory TotpVerifyResponse({
    required bool success,
    required List<String> backupCodes,
  }) = _TotpVerifyResponse;

  factory TotpVerifyResponse.fromJson(Map<String, dynamic> json) =>
      _$TotpVerifyResponseFromJson(json);
}