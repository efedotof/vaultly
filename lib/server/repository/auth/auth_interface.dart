import '../../model/auth/auth_response.dart';

abstract interface class AuthInterface {
  Future<AuthResponse> login();

  Future<AuthResponse> registration();

  Future<void> logout();
}
