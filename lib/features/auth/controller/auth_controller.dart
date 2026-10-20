import 'package:get/get.dart';

enum AuthStates { unauth, auth, error, registration}

class AuthController extends GetxController {
  RxString username =
      "".obs; // строка для username пользователя при входе и регистрации.
  RxString password = "".obs; // строка для пароля пользователя

  //метод входа
  void login() {

    
  }

  //метод регистрации
  void registration() {}

  //метод для проверки того есть ли зарегистрированный пользователь.
  bool checkUsernameFind({required String username}) {
    return false;
  }




  ///логика, одна страница для входа, отправляется на api/login,
  ///в случае если пользователя нет в системе, переход на страницу регистрации без указания username и password
}
