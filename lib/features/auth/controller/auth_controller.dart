import 'package:get/get.dart';

import '../../../server/model/auth/auth_response.dart';
import '../../../server/repository/auth/auth_repository.dart';

enum AuthStates {
  unauth,
  auth,
  error,
}

class AuthController extends GetxController implements AuthRepository {
  RxString username = "".obs; // строка для username пользователя при входе и регистрации.
  RxString password = "".obs; // строка для пароля пользователя

  //метод входа
  void login() {}

  //метод регистрации
  void registration() {}

  ///логика, одна страница для входа, отправляется на api/login,
  ///в случае если пользователя нет в системе, переход на страницу регистрации без указания username и password
}
