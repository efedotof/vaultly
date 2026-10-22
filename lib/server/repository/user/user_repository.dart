import 'package:get/get.dart';
import 'package:get/get_connect.dart';
import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/exception/unknown_error_exception.dart';
import 'package:vaulth_app/server/model/user/recovery_data_response.dart';
import 'package:vaulth_app/server/model/user/update_keys_request.dart';
import 'package:vaulth_app/server/model/user/update_recovery_keys_request.dart';
import 'package:vaulth_app/server/model/user/update_user_request.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto.dart';
import 'package:vaulth_app/server/repository/user/user_interface.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

class UserRepository extends GetConnect implements UserInterface {
  final config = Get.find<Config>();
  @override //get
  Future<UserProfileDto?> getCurrentUserProfile() async {
    try {
      final storage = Get.find<AuthLocalStorage>();
      final accessToken = await storage.getAccessToken();
      final resp = await get(
        config.userPath,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (resp.status.code == 200) {
        return UserProfileDto.fromJson(resp.body);
      }
      return null;
    } catch (e) {
      Logger.d("error: $e", tag: "AuthRepository: login");
      throw UnknownErrorException();
    }
  }

  @override //get
  Future<RecoveryDataResponse> getRecoveryData() async {
    try {} catch (e) {}
  }

  @override //get
  Future<UserProfileDto> getUserProfileById({required String id}) async {
    try {} catch (e) {}
  }

  @override //put
  Future<UserProfileDto> updateCurrentUser({
    required UpdateUserRequest request,
  }) async {
    try {} catch (e) {}
  }

  @override //post
  Future<void> updateKeys({required UpdateKeysRequest request}) async {
    try {} catch (e) {}
  }

  @override //post
  Future<void> updateRecoveryKeys({
    required UpdateRecoveryKeysRequest request,
  }) async {
    try {} catch (e) {}
  }
}
