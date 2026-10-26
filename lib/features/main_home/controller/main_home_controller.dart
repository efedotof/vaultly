import 'package:get/get.dart';
import 'package:vaulth_app/server/model/auth/token_validation_request.dart';
import 'package:vaulth_app/server/repository/auth/auth_interface.dart';
import 'package:vaulth_app/server/service/key/key_manager.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

class MainHomeController extends GetxController {
  final _currentIndex = 0.obs;
  int get currentIndex => _currentIndex.value;
  set currentIndex(int index) => _currentIndex.value = index;

  @override
  void onInit() {
    super.onInit();
    _verifyCheck();
  }

  Future<void> _verifyCheck() async {
    final authResp = Get.find<AuthInterface>();
    final localData = Get.find<AuthLocalStorage>();
    final keyManager = Get.find<KeyManagerService>();

    try {
      final userInfo = await localData.getUserInfo();
      final accessToken = await localData.getAccessToken();
      final userPassword = await localData.getPassword();

      final userId = userInfo?.id;
      if (userId == null ||
          userId.isEmpty ||
          accessToken == null ||
          accessToken.isEmpty ||
          userPassword == null ||
          userPassword.isEmpty) {
        await _goToLogin();
        return;
      }

      final resp = await authResp.validate(
        request: TokenValidationRequest(token: accessToken),
      );
      if (resp == null) {
        await _goToLogin();
        return;
      }

      final isChecking = await keyManager.verifyStoredKeyPairMatches(
        userId: userId,
        password: userPassword,
      );
      if (!isChecking) {
        Logger.d('ключи не сходятся для $userId', tag: 'MainHomeController');
        await _goToLogin();
      }
    } catch (e, s) {
      Logger.d('_verifyCheck: $e\n$s', tag: 'MainHomeController');
      await _goToLogin();
    }
  }

  Future<void> _goToLogin() async {
    await Get.find<AuthLocalStorage>().clearAuthData();
    Get.offAllNamed('/');
  }
}
