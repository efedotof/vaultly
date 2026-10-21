import 'package:get/get.dart';
import 'package:vaulth_app/features/profile/profile.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

enum AuthStates { loading, login, password }

class AuthController extends GetxController {
  RxString username =
      "".obs; // строка для username пользователя при входе и регистрации.
  RxString password = "".obs; // строка для пароля пользователя

  final state = AuthStates.login.obs;

  //метод входа
  void login() {
    try {
      state.value = AuthStates.loading;

      //вызываем api чтобы провести авторизацию

      Get.toNamed("/profile");

      state.value = AuthStates.login;
    } catch (e) {
      Logger.d("Произошла ошибка: $e", tag: "AuthController - login");
      Get.snackbar("Произошла ошибка", "попробуйте позже");
    }
  }

  //метод для смены с login на password
  void goToPassword() {
    state.value = AuthStates.password;
  }
}
