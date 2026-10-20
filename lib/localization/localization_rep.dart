import 'dart:ui';

import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/state_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationRep extends GetxController {
  late SharedPreferences _prefs;

  // Значение по умолчанию
  final Rx<Locale> _locale = const Locale('ru', 'RU').obs;

  Locale get locale => _locale.value;

  LocalizationRep();

  @override
  void onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
    getLocale();
  }

  // установить другую локаль
  void setLocale({
    required String languageCode,
    required String? countryCode,
  }) async {
    _locale.value = Locale(languageCode, countryCode);
    Get.updateLocale(_locale.value);
    await _prefs.setString('languageCode', languageCode);
    await _prefs.setString('countryCode', countryCode ?? "");
  }

  // получить локаль
  void getLocale() {
    final languageCode = _prefs.getString('languageCode') ?? "";
    final countryCode = _prefs.getString('countryCode') ?? "";

    if (languageCode.isEmpty) {
      _locale.value = const Locale('ru', 'RU');
      return;
    }

    // Если язык есть, применяем его
    _locale.value = Locale(languageCode, countryCode);
  }
}
