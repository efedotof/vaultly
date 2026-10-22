import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/localization/localization_rep.dart';
import 'package:vaulth_app/server/service/cache_service/cache_service.dart';
import 'package:vaulth_app/server/service/decrypt_service/decrypt_service.dart';
import 'package:vaulth_app/server/service/encrypt_service/encrypt_service.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';
import 'package:vaulth_app/storage/secure_storage_adapter.dart';

import 'config.dart';
import 'localization/localization.dart';
import 'route/router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //инициализация глобальных сервисов
  await Get.putAsync(()=> CacheService().init()); //сервис кэширования
  await Get.putAsync(()=> EncryptService().init());//сервис шифрования
  await Get.putAsync(()=> DecryptService().init());//сервис дешифрования
  
  //инициализация локализации
  Get.lazyPut(() => LocalizationRep());

  //инициализация конфига сервера
  Get.put(() => Config());

  //инициализация секретного хранилища
  Get.put(() => SecureStorageAdapter());

  //инициализация хранилища
  Get.put(() => AuthLocalStorage());

  runApp(VaultlyApp());
}

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
