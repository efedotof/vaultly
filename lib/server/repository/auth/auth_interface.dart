import 'package:vaulth_app/server/model/auth/auth_response/auth_response.dart';
import 'package:vaulth_app/server/model/auth/login_request/login_request.dart';
import 'package:vaulth_app/server/model/auth/logout_request/logout_request.dart';
import 'package:vaulth_app/server/model/auth/register_request/register_request.dart';
import 'package:vaulth_app/server/model/auth/token_validation_request/token_validation_request.dart';

abstract class AuthInterface {
  Future<AuthResponse> register(RegisterRequest request);
  Future<AuthResponse> login(LoginRequest request);
  Future<AuthResponse> validateToken(TokenValidationRequest request);
  Future<void> logout(LogoutRequest request);
  Future<String> healthCheck();
}
