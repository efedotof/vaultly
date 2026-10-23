import 'package:get/get.dart';
import 'package:vaulth_app/features/auth/controller/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    //контроллер для auth screen
    Get.lazyPut<AuthController>(() => AuthController());
  }
}
