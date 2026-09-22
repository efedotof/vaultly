import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/localization/localization_rep.dart';

import 'localization/localization.dart';
import 'route/router.dart';
import 'theme/app_theme.dart';

void main() {}

class VaultlyApp extends StatelessWidget {
  const VaultlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localC = Get.find<LocalizationRep>();
    return Obx(() {
      return GetMaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        getPages: AppRouter().router(),
        transitionDuration: Duration(milliseconds: 500),
        translations: Localization(),
        locale: localC.locale,
      );
    });
  }
}
