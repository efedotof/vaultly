import 'package:get/get_connect.dart';

import '../../model/auth/auth_response.dart';
import 'auth_interface.dart';

class AuthRepository extends GetConnect implements AuthInterface {
  @override
  Future<AuthResponse> login() {
    // TODO: implement login
    throw UnimplementedError();
  }

  @override
  Future<AuthResponse> registration() {
    // TODO: implement registration
    throw UnimplementedError();
  }

    @override
  Future<void> logout() {
    // TODO: implement logout
    throw UnimplementedError();
  }
}
