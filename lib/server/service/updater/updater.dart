import 'package:get/get.dart';

enum AppPlatform { mobile, desktop, web }

class UpdaterUnplatform extends GetxService {
  bool _isInit = false;

  Future<UpdaterUnplatform> init() async {
    _isInit = true;
    return this;
  }

  bool get isInitial => _isInit;
}
