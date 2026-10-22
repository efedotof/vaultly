import 'package:get/get.dart';
import 'package:vaulth_app/binding/auth_binding.dart';
import 'package:vaulth_app/binding/home_binging.dart';
import 'package:vaulth_app/binding/main_home_binding.dart';
import 'package:vaulth_app/binding/profile_binding.dart';
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
import 'package:vaulth_app/middleware/auth_middleware.dart';

class AppRouter {
  List<GetPage<dynamic>>? router() => [
    GetPage(
      name: '/',
      page: () => AuthScreen(),
      transition: Transition.cupertino,
      binding: AuthBinding(),
      middlewares: [AuthMiddleware()]
    ),
    GetPage(
      name: '/device',
      page: () => DeviceScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/document_viewer',
      page: () => DocumentViewerScreen(),
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
      binding: HomeBinging()
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
      binding: MainHomeBinding(),
    ),
    GetPage(
      name: '/notes',
      page: () => NotesScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/profile/:user',
      page: () => ProfileScreen(),
      transition: Transition.cupertino,
      binding: ProfileBinding(),
    ),
    GetPage(
      name: '/settings',
      page: () => SettingsScreen(),
      transition: Transition.cupertino,
    ),
  ];
}
