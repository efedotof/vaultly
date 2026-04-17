import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/app/app_modal.dart';
import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/repository/auth/auth_interface.dart';
import 'package:vaulth_app/server/repository/auth/auth_repository.dart';
import 'package:vaulth_app/server/repository/device/device_interface.dart';
import 'package:vaulth_app/server/repository/device/device_repository.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';
import 'package:vaulth_app/server/repository/file/file_repository.dart';
import 'package:vaulth_app/server/repository/folder/folder_interface.dart';
import 'package:vaulth_app/server/repository/folder/folder_repository.dart';
import 'package:vaulth_app/server/repository/server_key/server_key_interface.dart';
import 'package:vaulth_app/server/repository/server_key/server_key_repository.dart';
import 'package:vaulth_app/server/repository/temp_access/temp_access_interface.dart';
import 'package:vaulth_app/server/repository/temp_access/temp_access_repository.dart';
import 'package:vaulth_app/server/repository/totp/totp_interface.dart';
import 'package:vaulth_app/server/repository/totp/totp_repository.dart';
import 'package:vaulth_app/server/repository/user/user_interface.dart';
import 'package:vaulth_app/server/repository/user/user_repository.dart';
import 'package:vaulth_app/server/service/key_manager_service.dart';
import 'package:vaulth_app/server/service/local_file_cache.dart';
import 'package:vaulth_app/server/service/seed_phrase_service.dart';
import 'package:vaulth_app/server/service/shirm_encryption_service.dart';
import 'package:vaulth_app/server/service/update/update_service.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';
import 'package:vaulth_app/theme/interface/theme_interface.dart';
import 'package:vaulth_app/theme/interface/theme_repository.dart';

class AppRepository extends StatelessWidget {
  const AppRepository({super.key, required this.child, required this.appModal});
  final Widget child;
  final AppModel appModal;
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ThemeInterface>(
          create: (context) => ThemeRepository(preferences: appModal.prefs),
        ),
        RepositoryProvider(create: (context) => AuthLocalStorage()),
        RepositoryProvider(create: (context) => LocalFileCache()),
        RepositoryProvider(create: (context) => SeedPhraseService()),
        RepositoryProvider(
          create: (context) => UpdateService(
            githubRepoUrl: githubRepoUrl,
            appArchiveUrl: appArchiveUrl,
          ),
        ),
        RepositoryProvider<ServerKeyInterface>(
          create: (context) => ServerKeyRepository(
            baseUrl: serverKey,
            authLocalStorage: context.read<AuthLocalStorage>(),
          ),
        ),
        RepositoryProvider(create: (context) => KeyManagerService()),
        RepositoryProvider(create: (context) => ShirmEncryptionService()),
        RepositoryProvider<AuthInterface>(
          create: (context) => AuthRepository(authAddress: authKey),
        ),
        RepositoryProvider<DeviceInterface>(
          create: (context) => DeviceRepository(
            deviceAddress: deviceKey,
            authLocalStorage: context.read<AuthLocalStorage>(),
          ),
        ),
        RepositoryProvider<FileInterface>(
          create: (context) => FileRepository(
            keyManager: context.read<KeyManagerService>(),
            fileAddress: fileKey,
            authLocalStorage: context.read<AuthLocalStorage>(),
          ),
        ),
        RepositoryProvider<FolderInterface>(
          create: (context) => FolderRepository(
            folderAddress: folderkey,
            authLocalStorage: context.read<AuthLocalStorage>(),
          ),
        ),
        RepositoryProvider<UserInterface>(
          create: (context) => UserRepository(
            userAddress: userKey,
            authLocalStorage: context.read<AuthLocalStorage>(),
          ),
        ),

        RepositoryProvider<TempAccessInterface>(
          create: (context) => TempAccessRepository(
            baseUrl: tempAccessKey,
            authLocalStorage: context.read<AuthLocalStorage>(),
          ),
        ),
        RepositoryProvider<TotpInterface>(
          create: (context) => TotpRepository(
            totpAddress: authKey,
            authLocalStorage: context.read<AuthLocalStorage>(),
          ),
        ),
      ],
      child: child,
    );
  }
}
