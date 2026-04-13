import 'package:vaulth_app/server/model/totp/totp_disable_request/totp_disable_request.dart';
import 'package:vaulth_app/server/model/totp/totp_setup_response/totp_setup_response.dart';
import 'package:vaulth_app/server/model/totp/totp_verify_request/totp_verify_request.dart';
import 'package:vaulth_app/server/model/totp/totp_verify_response/totp_verify_response.dart';

abstract interface class TotpInterface {
  Future<TotpSetupResponse> setupTotp();
  Future<TotpVerifyResponse> verifyTotp(TotpVerifyRequest request);
  Future<void> disableTotp(TotpDisableRequest request);
}
