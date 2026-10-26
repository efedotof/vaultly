import 'package:get/get.dart';
import 'package:vaulth_app/server/model/auth/token_validation_request.dart';
import 'package:vaulth_app/server/repository/auth/auth_interface.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  Future<GetNavConfig?> redirectDelegate(GetNavConfig route) async {
    try {
      final storage = Get.find<AuthLocalStorage>();

      final userInfo = await storage.getUserInfo();
      final accessToken = await storage.getAccessToken();

      Logger.d("userInfo: $userInfo accessToken: $accessToken", tag: "AuthMiddleware");

      if (userInfo == null || accessToken == null || accessToken == "") {
        return GetNavConfig.fromRoute('/');
      }

      final authResp = Get.find<AuthInterface>();

      final verifyToken = await authResp
          .validate(request: TokenValidationRequest(token: accessToken))
          .then((v) {
            if (v == null || v.isAuth == false) return false;

            return true;
          });

      if (verifyToken) return GetNavConfig.fromRoute('/main_home');
      return GetNavConfig.fromRoute('/');
    } catch (e) {
      return GetNavConfig.fromRoute('/');
    }
  }
}
