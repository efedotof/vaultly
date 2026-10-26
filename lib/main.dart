import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/binding/app_binding.dart';
import 'package:vaulth_app/features/global_widget/connection_checher/controller/connection_checker_controller.dart';
import 'package:vaulth_app/localization/localization_rep.dart';
import 'package:vaulth_app/server/service/cache_service/cache_service.dart';
import 'package:vaulth_app/server/service/decrypt_service/decrypt_service.dart';
import 'package:vaulth_app/server/service/encrypt_service/encrypt_service.dart';
import 'package:vaulth_app/server/service/key/device_id_generator.dart';
import 'package:vaulth_app/server/service/key/key_manager.dart';
import 'package:vaulth_app/server/service/key/recovery_phase.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';
import 'package:vaulth_app/storage/secure_storage_adapter.dart';
import 'config.dart';
import 'localization/localization.dart';
import 'route/router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //инициализация конфига сервера
  Get.put(Config());

  //инициализируем чекинг интернета и доступности сервера
  Get.put(ConnectionCheckerController());
  
  //инициализация глобальных сервисов
  await Get.putAsync(() => CacheService().init()); //сервис кэширования
  await Get.putAsync(() => EncryptService().init()); //сервис шифрования
  await Get.putAsync(() => DecryptService().init()); //сервис дешифрования
  await Get.putAsync(() => DeviceIdGenerator().init()); //сервис генерации айди устройства
  await Get.putAsync(() => KeyManagerService().init()); //сервис управления, создания,сохранения ключей пользователя.
  await Get.putAsync(() => RecoveryPhase().init()); //сервис создания seed 
  
  //инициализация локализации
  Get.lazyPut(() => LocalizationRep());

  //инициализация секретного хранилища
  Get.put(SecureStorageAdapter(), permanent: true);

  //инициализируем profileController для 


  //инициализация хранилища
  final storage = Get.put(AuthLocalStorage(), permanent: true);

  //инициализируем кэш
  await storage.initCache();


  runApp(VaultlyApp());
}

class VaultlyApp extends StatelessWidget {
  const VaultlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localC = Get.find<LocalizationRep>();
    return Obx(() {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialBinding: AppBinding(),
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
