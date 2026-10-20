import 'package:get/get.dart';
import 'package:vaulth_app/features/auth/controller/auth_controller.dart';
import 'package:vaulth_app/server/repository/auth/auth_interface.dart';
import 'package:vaulth_app/server/repository/auth/auth_repository.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    //сервис api для auth
    Get.lazyPut<AuthInterface>(() => AuthRepository());
    //контроллер для auth screen
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
