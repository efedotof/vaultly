import 'package:get/get.dart';
import 'package:vaulth_app/features/main_home/controller/main_home_controller.dart';
import 'package:vaulth_app/features/profile/controller/profile_controller.dart';

class MainHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainHomeController());
    Get.lazyPut(() => ProfileController());

  }
}
