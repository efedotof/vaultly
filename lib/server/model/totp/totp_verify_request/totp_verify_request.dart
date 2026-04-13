import 'package:freezed_annotation/freezed_annotation.dart';

part 'totp_verify_request.freezed.dart';
part 'totp_verify_request.g.dart';

@freezed
abstract class TotpVerifyRequest with _$TotpVerifyRequest {
  const factory TotpVerifyRequest({required String code}) = _TotpVerifyRequest;

  factory TotpVerifyRequest.fromJson(Map<String, dynamic> json) =>
      _$TotpVerifyRequestFromJson(json);
}
