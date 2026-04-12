// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AuthScreen]
class AuthRoute extends PageRouteInfo<void> {
  const AuthRoute({List<PageRouteInfo>? children})
    : super(AuthRoute.name, initialChildren: children);

  static const String name = 'AuthRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AuthScreen();
    },
  );
}

/// generated route for
/// [DeviceScreen]
class DeviceRoute extends PageRouteInfo<void> {
  const DeviceRoute({List<PageRouteInfo>? children})
    : super(DeviceRoute.name, initialChildren: children);

  static const String name = 'DeviceRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DeviceScreen();
    },
  );
}

/// generated route for
/// [DocumentViewerScreen]
class DocumentViewerRoute extends PageRouteInfo<DocumentViewerRouteArgs> {
  DocumentViewerRoute({
    Key? key,
    required FileDto file,
    List<PageRouteInfo>? children,
  }) : super(
         DocumentViewerRoute.name,
         args: DocumentViewerRouteArgs(key: key, file: file),
         initialChildren: children,
       );

  static const String name = 'DocumentViewerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DocumentViewerRouteArgs>();
      return DocumentViewerScreen(key: args.key, file: args.file);
    },
  );
}

class DocumentViewerRouteArgs {
  const DocumentViewerRouteArgs({this.key, required this.file});

  final Key? key;

  final FileDto file;

  @override
  String toString() {
    return 'DocumentViewerRouteArgs{key: $key, file: $file}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DocumentViewerRouteArgs) return false;
    return key == other.key && file == other.file;
  }

  @override
  int get hashCode => key.hashCode ^ file.hashCode;
}

/// generated route for
/// [FolderScreen]
class FolderRoute extends PageRouteInfo<FolderRouteArgs> {
  FolderRoute({
    Key? key,
    required String folderId,
    List<PageRouteInfo>? children,
  }) : super(
         FolderRoute.name,
         args: FolderRouteArgs(key: key, folderId: folderId),
         rawPathParams: {'folderId': folderId},
         initialChildren: children,
       );

  static const String name = 'FolderRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<FolderRouteArgs>(
        orElse: () =>
            FolderRouteArgs(folderId: pathParams.getString('folderId')),
      );
      return FolderScreen(key: args.key, folderId: args.folderId);
    },
  );
}

class FolderRouteArgs {
  const FolderRouteArgs({this.key, required this.folderId});

  final Key? key;

  final String folderId;

  @override
  String toString() {
    return 'FolderRouteArgs{key: $key, folderId: $folderId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FolderRouteArgs) return false;
    return key == other.key && folderId == other.folderId;
  }

  @override
  int get hashCode => key.hashCode ^ folderId.hashCode;
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [KeysManagerScreen]
class KeysManagerRoute extends PageRouteInfo<void> {
  const KeysManagerRoute({List<PageRouteInfo>? children})
    : super(KeysManagerRoute.name, initialChildren: children);

  static const String name = 'KeysManagerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const KeysManagerScreen();
    },
  );
}

/// generated route for
/// [MainHomeScreen]
class MainHomeRoute extends PageRouteInfo<void> {
  const MainHomeRoute({List<PageRouteInfo>? children})
    : super(MainHomeRoute.name, initialChildren: children);

  static const String name = 'MainHomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainHomeScreen();
    },
  );
}

/// generated route for
/// [ProfileScreen]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfileScreen();
    },
  );
}

/// generated route for
/// [SettingsScreen]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SettingsScreen();
    },
  );
}
