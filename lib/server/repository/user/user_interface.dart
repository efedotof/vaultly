import 'package:vaulth_app/server/model/user/recovery_data_response/recovery_data_response.dart';
import 'package:vaulth_app/server/model/user/update_keys_request/update_keys_request.dart';
import 'package:vaulth_app/server/model/user/update_recovery_keys_request/update_recovery_keys_request.dart';
import 'package:vaulth_app/server/model/user/update_user_request/update_user_request.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto/user_profile_dto.dart';

abstract class UserInterface {
  Future<UserProfileDto> getCurrentUserProfile();
  Future<UserProfileDto> updateCurrentUser(UpdateUserRequest request);
  Future<UserProfileDto> getUserProfileById(String id);
  Future<String> getUserEncryptedPrivateKey();
  Future<String> getUserSalt();

  Future<void> updateRecoveryKeys({required UpdateRecoveryKeysRequest request});
  Future<RecoveryDataResponse> getRecoveryData();
  Future<void> updateKeys({required UpdateKeysRequest request});
}
