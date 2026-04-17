import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/app/cubit/file_upload_cubit.dart';
import 'package:vaulth_app/features/auth/cubit/auth_cubit.dart';
import 'package:vaulth_app/features/document_viewer/cubit/document_viewer_cubit.dart';
import 'package:vaulth_app/features/folder/cubit/folder_cubit.dart';
import 'package:vaulth_app/features/home/cubit/batch_cache_cubit.dart';
import 'package:vaulth_app/features/home/cubit/home_cubit.dart';
import 'package:vaulth_app/features/notes/cubit/notes_cubit.dart';
import 'package:vaulth_app/features/profile/cubit/profile_cubit.dart';
import 'package:vaulth_app/features/settings/cubit/settings_cubit.dart';
import 'package:vaulth_app/server/repository/auth/auth_interface.dart';
import 'package:vaulth_app/server/repository/device/device_interface.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';
import 'package:vaulth_app/server/repository/folder/folder_interface.dart';
import 'package:vaulth_app/server/repository/totp/totp_interface.dart';
import 'package:vaulth_app/server/repository/user/user_interface.dart';
import 'package:vaulth_app/server/service/file_decryption_service.dart';
import 'package:vaulth_app/server/service/key_manager_service.dart';
import 'package:vaulth_app/server/service/key_manager_service_web.dart';
import 'package:vaulth_app/server/service/local_file_cache.dart';
import 'package:vaulth_app/server/service/seed_phrase_service.dart';
import 'package:vaulth_app/server/service/update/update_service.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';
import 'package:vaulth_app/theme/theme_app/theme_cubit.dart';
import 'package:vaulth_app/theme/interface/theme_interface.dart';
import 'package:vaulth_app/theme/theme_code/code_highlight_theme_cubit.dart';

import 'app_modal.dart';

class AppBloc extends StatefulWidget {
  const AppBloc({super.key, required this.child, required this.appModel});
  final Widget child;
  final AppModel appModel;
  @override
  State<AppBloc> createState() => _AppBlocState();
}

class _AppBlocState extends State<AppBloc> {
  late final dynamic keyManagerService;

  @override
  void initState() {
    super.initState();
    keyManagerService = kIsWeb ? KeyManagerServiceWeb() : KeyManagerService();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ThemeCubit(themeInterface: context.read<ThemeInterface>()),
        ),
        BlocProvider(
          create: (context) => CodeHighlightThemeCubit(widget.appModel.prefs),
        ),
        BlocProvider(
          create: (context) => AuthCubit(
            authRepository: context.read<AuthInterface>(),
            deviceRepository: context.read<DeviceInterface>(),
            keyManagerService: keyManagerService,
            authLocalService: context.read<AuthLocalStorage>(),
            userInterface: context.read<UserInterface>(),
            updateService: context.read<UpdateService>(),
          ),
        ),
        BlocProvider(
          create: (context) => FileUploadCubit(
            fileRepository: context.read<FileInterface>(),
            keyManagerService: keyManagerService,
            authLocalStorage: context.read<AuthLocalStorage>(),
          ),
        ),
        BlocProvider(
          create: (context) => FolderCubit(
            folderRepository: context.read<FolderInterface>(),
            fileRepository: context.read<FileInterface>(),
            keyManagerService: keyManagerService,
            authLocalStorage: context.read<AuthLocalStorage>(),
          ),
        ),
        BlocProvider(
          create: (context) => HomeCubit(
            fileRepository: context.read<FileInterface>(),
            folderRepository: context.read<FolderInterface>(),
            keyManagerService: keyManagerService,
            authLocalStorage: context.read<AuthLocalStorage>(),
            localFileCache: context.read<LocalFileCache>(),
          ),
        ),
        BlocProvider(
          create: (context) =>
              ProfileCubit(userRepository: context.read<UserInterface>()),
        ),
        BlocProvider(
          create: (context) => SettingsCubit(
            userRepository: context.read<UserInterface>(),
            authRepository: context.read<AuthInterface>(),
            deviceRepository: context.read<DeviceInterface>(),
            keyManager: keyManagerService,
            fileCache: context.read<LocalFileCache>(),
            authStorage: context.read<AuthLocalStorage>(),
            authCubit: context.read<AuthCubit>(),
            totpInterface: context.read<TotpInterface>(),
            seedPhraseService: context.read<SeedPhraseService>(),
            updateService: context.read<UpdateService>(),
          ),
        ),
        BlocProvider(
          create: (context) => DocumentViewerCubit(
            fileRepository: context.read<FileInterface>(),
            keyManagerService: keyManagerService,
            localFileCache: context.read<LocalFileCache>(),
            authCubit: context.read<AuthCubit>(),
          ),
        ),
        BlocProvider(
          create: (context) => BatchCacheCubit(
            decryptionService: FileDecryptionService(
              fileRepository: context.read<FileInterface>(),
              keyManagerService: keyManagerService,
              localFileCache: context.read<LocalFileCache>(),
            ),
            authCubit: context.read<AuthCubit>(),
          ),
        ),
        BlocProvider(
          create: (context) =>
              NotesCubit(fileRepository: context.read<FileInterface>()),
        ),
      ],
      child: widget.child,
    );
  }
}
