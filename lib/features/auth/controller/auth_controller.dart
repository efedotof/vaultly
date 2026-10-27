import 'package:get/get.dart';
import 'package:vaulth_app/server/exception/auth_error_exception.dart';
import 'package:vaulth_app/server/exception/unknown_error_exception.dart';
import 'package:vaulth_app/server/exception/validation_error_exception.dart';
import 'package:vaulth_app/server/model/auth/login_request.dart';
import 'package:vaulth_app/server/repository/auth/auth_interface.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

enum AuthStates { loading, login, password }

class AuthController extends GetxController {
  RxString username =
      "".obs; // строка для username пользователя при входе и регистрации.
  RxString password = "".obs; // строка для пароля пользователя

  final state = AuthStates.login.obs;

  //метод входа
  Future<void> login() async {
    try {
      state.value = AuthStates.loading;

      final authRep = Get.find<AuthInterface>();

      await authRep.login(
        request: LoginRequest(
          username: username.value,
          password: password.value,
        ),
      );

      state.value = AuthStates.login;
      Get.offAllNamed('/main_home');
    } on AuthErrorException catch (e) {
      Logger.d(
        "AuthErrorException: ${e.message}",
        tag: "AuthController - login",
      );
      Get.toNamed("/profile/create_profile");
    } on ValidationErrorException catch (_) {
      state.value = AuthStates.login;
    } on UnknownErrorException catch (_) {
      state.value = AuthStates.login;
    } catch (e, s) {
      Logger.d("Произошла ошибка: $e\n$s", tag: "AuthController - login");
      Get.snackbar("Произошла ошибка", "попробуйте позже");
    }
  }

  //метод для смены с login на password
  void goToNext() {
    if (state.value == AuthStates.login && username.value != "") {
      state.value = AuthStates.password;
    }

    if (state.value == AuthStates.password) state.value = AuthStates.password;
  }
}
