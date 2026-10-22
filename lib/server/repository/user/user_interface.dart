import 'package:vaulth_app/server/model/user/recovery_data_response.dart';
import 'package:vaulth_app/server/model/user/update_keys_request.dart';
import 'package:vaulth_app/server/model/user/update_recovery_keys_request.dart';
import 'package:vaulth_app/server/model/user/update_user_request.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto.dart';

abstract interface class UserInterface {


  //получить текущего пользователя (get)
  Future<UserProfileDto?> getCurrentUserProfile();

  //обновить информацию о пользователе (текущем) put
  Future<UserProfileDto> updateCurrentUser({required UpdateUserRequest request});
  
  //получить профиль по id (get)
  Future<UserProfileDto> getUserProfileById({required String id});

  //обновить ключи восстановления (post)
  Future<void> updateRecoveryKeys({required UpdateRecoveryKeysRequest request});
  
  //получить recovery data (get)
  Future<RecoveryDataResponse> getRecoveryData();

  //post
  Future<void> updateKeys({required UpdateKeysRequest request});
}

