import 'package:get/get.dart';

enum AppPlatform { mobile, desktop, web }

class UpdaterUnplatform extends GetxService {
  UpdaterUnplatform() {
    _checkPlatform();
  }

  void _checkPlatform() {}
}
