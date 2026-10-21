import 'package:get/get.dart';

class Localization extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ru_RU':{
      'welcome': "Добро пожаловать",
      "continue": "Продолжить",
      "username": "имя пользователя"
    },

    'en_US': {
      'welcome': "Welcome",
      "continue":"Continue",
      "username":"username"
    }
  };
}
