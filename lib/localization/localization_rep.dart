import 'dart:ui';

import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/state_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationRep extends GetxController {
  SharedPreferences _prefs;

  final Rx<Locale> _locale = Locale('ru', 'RU').obs;

  Locale get locale => _locale.value;

  LocalizationRep({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  void onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
    getLocale();
  }

  //установить другую локаль
  void setLocale({
    required String languageCode,
    required String? countryCode,
  }) async {
    _locale.value = Locale(languageCode, countryCode);
    Get.updateLocale(_locale.value);
    await _prefs.setString('languageCode', languageCode);
    await _prefs.setString('countryCode', countryCode ?? "");
  }

  //получить локаль
  void getLocale() {
    String getLanguageCode = _prefs.getString('languageCode') ?? "";
    String getCountryCode = _prefs.getString('countryCode') ?? "";

    if ((getLanguageCode.isEmpty && getCountryCode.isEmpty) ||
        (getLanguageCode == "" && getCountryCode == "")) {
      _locale.value = Locale('ru', 'RU');
    }
    _locale.value = Locale(getLanguageCode, getCountryCode);
  }
}
