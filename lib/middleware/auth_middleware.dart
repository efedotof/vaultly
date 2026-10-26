import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      if (route == '/' && Get.find<AuthLocalStorage>().hasCachedSession) {
        return const RouteSettings(name: '/main_home');
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
