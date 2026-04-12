import 'package:vaulth_app/server/model/user/update_user_request/update_user_request.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto/user_profile_dto.dart';

abstract class UserInterface {
  Future<UserProfileDto> getCurrentUserProfile();
  Future<UserProfileDto> updateCurrentUser(UpdateUserRequest request);
  Future<UserProfileDto> getUserProfileById(String id);
  Future<String> getUserEncryptedPrivateKey();
  Future<String> getUserSalt();
}
