import 'dart:async';

import 'package:get/get.dart';
import 'package:vaulth_app/features/auth/controller/auth_controller.dart';
import 'package:vaulth_app/server/exception/username_already_exists_exception.dart';
import 'package:vaulth_app/server/exception/validation_error_exception.dart';
import 'package:vaulth_app/server/model/auth/register_request.dart';
import 'package:vaulth_app/server/model/user/update_user_request.dart';
import 'package:vaulth_app/server/repository/auth/auth_interface.dart';
import 'package:vaulth_app/server/repository/user/user_interface.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

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

  AuthLocalStorage get _storage => Get.find<AuthLocalStorage>();

  String get username => _storage.cachedUserInfo?.username ?? '';
  String get email => _storage.cachedUserInfo?.email ?? '';
  String get avatarUrl => _storage.cachedUserInfo?.avatarUrl ?? '';
  String get firstName => _storage.cachedUserInfo?.firstName ?? '';
  String get lastName => _storage.cachedUserInfo?.lastName ?? '';
  int get storageUsed => _storage.cachedUserInfo?.storageUsed ?? 0;
  int get storageLimit => _storage.cachedUserInfo?.storageLimit ?? 0;

  String get fullname => '$firstName $lastName'.trim();

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
    final usernameInput = authController.username.value;
    final password = authController.password.value;

    try {
      if (usernameInput.isNotEmpty && password.isNotEmpty) {
        final authResp = Get.find<AuthInterface>();

        await authResp.registration(
          request: RegisterRequest(
            username: usernameInput,
            password: password,
            firstName: firstName,
            lastName: lastName,
            email: email,
          ),
        );
      }

      if (totpEnabled) {
        Get.offAllNamed('/totp/setup');
      } else {
        Get.offAllNamed('/main_home');
      }
    } catch (e, s) {
      Logger.d('createProfile: $e\n$s', tag: _tag);
      Get.snackbar('Ошибка', 'Не удалось создать профиль');
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String usernameInput,
  }) async {
    Logger.d(
      'updateProfile: firstName="$firstName" lastName="$lastName" '
      'username="$usernameInput"',
      tag: _tag,
    );

    if (firstName.isEmpty) {
      Get.snackbar('Ошибка', 'Введите имя');
      return;
    }
    if (usernameInput.isEmpty) {
      Get.snackbar('Ошибка', 'Введите username');
      return;
    }

    state.value = ProfileStates.loading;
    try {
      final userRepo = Get.find<UserInterface>();
      final updated = await userRepo.updateCurrentUser(
        request: UpdateUserRequest(
          firstName: firstName,
          lastName: lastName,
          username: usernameInput,
        ),
      );

      await _storage.saveUserInfo(updated);

      state.value = ProfileStates.myProfile;
      Get.snackbar('Успех', 'Профиль обновлён');
    } on UsernameAlreadyExistsException {
      state.value = ProfileStates.updateProfile;
      Get.snackbar('Ошибка', 'Этот username уже занят');
    } on ValidationErrorException catch (e) {
      state.value = ProfileStates.updateProfile;
      Get.snackbar('Ошибка', e.message);
    } catch (e, s) {
      Logger.d('updateProfile: $e\n$s', tag: _tag);
      state.value = ProfileStates.updateProfile;
      Get.snackbar('Ошибка', 'Не удалось обновить профиль');
    }
  }
}
