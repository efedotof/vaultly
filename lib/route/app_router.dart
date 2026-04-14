import "package:auto_route/auto_route.dart";
import 'package:flutter/material.dart';

import 'package:vaulth_app/features/features.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: AuthRoute.page, path: "/"),
    AutoRoute(
      page: MainHomeRoute.page,
      path: "/main_home",
      children: [
        AutoRoute(page: HomeRoute.page, path: "home"),
        AutoRoute(page: NotesRoute.page, path: "notes"),
        AutoRoute(page: ProfileRoute.page, path: "profile"),
        AutoRoute(page: SettingsRoute.page, path: "setting"),
      ],
    ),
    AutoRoute(page: FolderRoute.page, path: "/folder"),
    AutoRoute(page: DocumentViewerRoute.page, path: "/document_viewer"),
    AutoRoute(page: DeviceRoute.page, path: "/device"),
    AutoRoute(page: KeysManagerRoute.page, path: "/keys"),
  ];
}
