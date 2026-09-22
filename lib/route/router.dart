import 'package:get/get.dart';
import 'package:vaulth_app/features/auth/auth.dart';
import 'package:vaulth_app/features/device/device.dart';
import 'package:vaulth_app/features/document_viewer/document_viewer.dart';
import 'package:vaulth_app/features/folder/view/view.dart';
import 'package:vaulth_app/features/home/home.dart';
import 'package:vaulth_app/features/keys_manager/view/view.dart';
import 'package:vaulth_app/features/main_home/view/main_home_screen.dart';
import 'package:vaulth_app/features/notes/notes.dart';
import 'package:vaulth_app/features/profile/profile.dart';
import 'package:vaulth_app/features/settings/settings.dart';

class AppRouter {
  List<GetPage<dynamic>>? router() => [
    GetPage(
      name: '/',
      page: () => AuthScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/login',
      page: () => LoginScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/registration',
      page: () => RegistrationScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/device',
      page: () => DeviceScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/document_viewver',
      page: () => DocumentViewverScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/folder',
      page: () => FolderScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/home',
      page: () => HomeScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/keys_manager',
      page: () => KeysManagerScreen(),
      transition: Transition.cupertino,
    ),

    GetPage(
      name: '/main_home',
      page: () => MainHomeScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/notes',
      page: () => NotesScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/profile',
      page: () => ProfileScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/settings',
      page: () => SettingsScreen(),
      transition: Transition.cupertino,
    ),
  ];
}
