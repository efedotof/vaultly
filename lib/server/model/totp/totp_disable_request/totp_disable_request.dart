import 'package:freezed_annotation/freezed_annotation.dart';

part 'totp_disable_request.freezed.dart';
part 'totp_disable_request.g.dart';

@freezed
abstract class TotpDisableRequest with _$TotpDisableRequest {
  const factory TotpDisableRequest({required String code}) =
      _TotpDisableRequest;

  factory TotpDisableRequest.fromJson(Map<String, dynamic> json) =>
      _$TotpDisableRequestFromJson(json);
}
