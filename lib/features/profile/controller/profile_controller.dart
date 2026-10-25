import 'dart:async';

import 'package:get/get.dart';
import 'package:vaulth_app/features/auth/controller/auth_controller.dart';
import 'package:vaulth_app/server/model/auth/register_request.dart';
import 'package:vaulth_app/server/repository/auth/auth_interface.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

enum ProfileStates {
  loading,
  myProfile,
  otherProfile,
  createProfile,
  updateProfile,
}

class ProfileController extends GetxController {
  static const _tag = 'ProfileController';

  final state = ProfileStates.loading.obs;
  final userId = 'my_profile'.obs;

  @override
  void onInit() {
    super.onInit();
    final param = Get.parameters['user'];
    userId.value = param ?? 'my_profile';
    Logger.d('onInit: user=${userId.value}', tag: _tag);
    _updateStates(userId.value);
  }

  void _updateStates(String id) {
    switch (id) {
      case 'my_profile':
        state.value = ProfileStates.myProfile;
        break;
      case 'create_profile':
        state.value = ProfileStates.createProfile;
        break;
      case 'update_my_profile':
        state.value = ProfileStates.updateProfile;
        break;
      default:
        state.value = ProfileStates.otherProfile;
        break;
    }
    Logger.d('state ${state.value}', tag: _tag);
  }

  Future<void> createProfile({
    required String firstName,
    required String lastName,
    required String email,
    required bool totpEnabled,
  }) async {
    Logger.d(
      'createProfile: firstName="$firstName" lastName="$lastName" '
      'email="$email" totpEnabled=$totpEnabled',
      tag: _tag,
    );

    if (firstName.isEmpty) {
      Get.snackbar('Ошибка', 'Введите имя');
      return;
    }
    if (email.isNotEmpty &&
        !RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      Get.snackbar('Ошибка', 'Некорректный email');
      return;
    }

    final authController = Get.find<AuthController>();

    final username = authController.username.value;
    final password = authController.password.value;

    if (username != "" || password != "") {
      final authResp = Get.find<AuthInterface>();

      authResp.registration(
        request: RegisterRequest(
          username: username,
          password: password,
          firstName: firstName,
          lastName: lastName,
          email: email,
        ),
      );
    }

    if (totpEnabled) {
      Get.toNamed('/totp/setup');
    } else {
      Get.offAllNamed('/main_home');
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    Logger.d('updateProfile', tag: _tag);
  }
}
