import 'package:vaulth_app/server/model/auth/auth_info.dart';
import 'package:vaulth_app/server/model/auth/login_request.dart';
import 'package:vaulth_app/server/model/auth/login_with_totp_request.dart';
import 'package:vaulth_app/server/model/auth/logout_request.dart';
import 'package:vaulth_app/server/model/auth/recover_request.dart';
import 'package:vaulth_app/server/model/auth/recovery_challenge_request.dart';
import 'package:vaulth_app/server/model/auth/recovery_challenge_response.dart';
import 'package:vaulth_app/server/model/auth/register_request.dart';
import 'package:vaulth_app/server/model/auth/token_validation_request.dart';
import 'package:vaulth_app/server/model/auth/totp_disable_request.dart';
import 'package:vaulth_app/server/model/auth/totp_setup_response.dart';
import 'package:vaulth_app/server/model/auth/totp_verify_request.dart';
import 'package:vaulth_app/server/model/auth/totp_verify_response.dart';

abstract interface class AuthInterface {
  
  //логин
  Future<AuthInfo?> login({required LoginRequest request});

  //регистрация
  Future<AuthInfo> registration({required RegisterRequest request});

  //вход по totp
  Future<AuthInfo> totpLogin({required LoginWithTotpRequest request});

  //включить двухфакторку
  Future<TotpSetupResponse> totpSetup();

  //проверка двухфакторки
  Future<TotpVerifyResponse> totpVerify({required TotpVerifyRequest request});

  //отключить двухфакторку
  Future<void> totpDisable({required TotpDisableRequest request});

  //проверка токена
  Future<AuthInfo?> validate({required TokenValidationRequest request});

  //восстановить
  Future<AuthInfo> recovery({required RecoverRequest request});

  //получение одноразового nonce
  Future<RecoveryChallengeResponse> recoveryChallenge({
    required RecoveryChallengeRequest request,
  });

  //выход
  Future<void> logout({required LogoutRequest request});
}
