import 'package:get/get.dart';
import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/api_client.dart';
import 'package:vaulth_app/server/repository/auth/auth_interface.dart';
import 'package:vaulth_app/server/repository/auth/auth_repository.dart';
import 'package:vaulth_app/server/repository/device/device_interface.dart';
import 'package:vaulth_app/server/repository/device/device_repository.dart';
import 'package:vaulth_app/server/repository/device_pairing/device_pairing_interface.dart';
import 'package:vaulth_app/server/repository/device_pairing/device_pairing_repository.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';
import 'package:vaulth_app/server/repository/file/file_repository.dart';
import 'package:vaulth_app/server/repository/folder/folder_interface.dart';
import 'package:vaulth_app/server/repository/folder/folder_repository.dart';
import 'package:vaulth_app/server/repository/server_key/server_key_interface.dart';
import 'package:vaulth_app/server/repository/server_key/server_key_repository.dart';
import 'package:vaulth_app/server/repository/temp_access/temp_access_interface.dart';
import 'package:vaulth_app/server/repository/temp_access/temp_access_repository.dart';
import 'package:vaulth_app/server/repository/user/user_interface.dart';
import 'package:vaulth_app/server/repository/user/user_repository.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {

    //инициализация api
    Get.put(ApiClient(config: Get.find<Config>()));

    //инициализация репозиториев и интерфейсов
    Get.lazyPut<AuthInterface>(
      () => AuthRepository(
        Get.find<ApiClient>(),
        Get.find<Config>(),
        Get.find<AuthLocalStorage>(),
      ),
    );

    Get.lazyPut<DeviceInterface>(
      () => DeviceRepository(
        apiClient: Get.find<ApiClient>(),
        config: Get.find<Config>(),
      ),
    );

    Get.lazyPut<DevicePairingInterface>(
      () => DevicePairingRepository(
        apiClient: Get.find<ApiClient>(),
        config: Get.find<Config>(),
      ),
    );

    Get.lazyPut<FileInterface>(
      () => FileRepository(
        apiClient: Get.find<ApiClient>(),
        config: Get.find<Config>(),
      ),
    );

    Get.lazyPut<FolderInterface>(
      () => FolderRepository(
        apiClient: Get.find<ApiClient>(),
        config: Get.find<Config>(),
      ),
    );

    Get.lazyPut<ServerKeyInterface>(
      () => ServerKeyRepository(
        apiClient: Get.find<ApiClient>(),
        config: Get.find<Config>(),
      ),
    );

    Get.lazyPut<TempAccessInterface>(
      () => TempAccessRepository(
        apiClient: Get.find<ApiClient>(),
        config: Get.find<Config>(),
      ),
    );

    Get.lazyPut<UserInterface>(
      () => UserRepository(
        Get.find<ApiClient>(),
        Get.find<Config>(),
        Get.find<AuthLocalStorage>(),
      ),
    );
  }
}
