import 'package:get/get_instance/get_instance.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/features/home/controller/batch_cache_controller.dart';
import 'package:vaulth_app/features/home/controller/files_uploade_controller.dart';
import 'package:vaulth_app/features/home/controller/home_controller.dart';

class HomeBinging extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BatchCacheController());
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => FilesUploadeController());
  }
}
