import 'package:freezed_annotation/freezed_annotation.dart';

part 'totp_setup_response.freezed.dart';
part 'totp_setup_response.g.dart';

@freezed
abstract class TotpSetupResponse with _$TotpSetupResponse {
  const factory TotpSetupResponse({
    required String secret,
    required String qrCodeUrl,
  }) = _TotpSetupResponse;

  factory TotpSetupResponse.fromJson(Map<String, dynamic> json) =>
      _$TotpSetupResponseFromJson(json);
}
