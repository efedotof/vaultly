import 'package:get/get.dart';

enum AuthStates { auth, login, password}

class AuthController extends GetxController {
  RxString username =
      "".obs; // строка для username пользователя при входе и регистрации.
  RxString password = "".obs; // строка для пароля пользователя

  final state = AuthStates.login.obs;


  //метод входа
  void login() {
    state.value = AuthStates.password;
  }

  //метод регистрации
  void registration() {}

  //метод для проверки того есть ли зарегистрированный пользователь.
  bool checkUsernameFind({required String username}) {
    return false;
  }
}
