import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaulth_app/app/app_initializer.dart';
import 'package:media_kit/media_kit.dart';
import 'package:vaulth_app/app/app_modal.dart';
import 'package:vaulth_app/theme/theme_app/theme_cubit.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'route/app_router.dart';
import 'server/service/logger_service.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final LoggerService logger = LoggerService();
  await logger.init();
  MediaKit.ensureInitialized();
  final appModal = AppModel(prefs: await SharedPreferences.getInstance());
  if (!kIsWeb) {
    if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (Platform.isIOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  }
  runApp(AppInitializer(appModel: appModal, child: VaultlyApp()));
}

class VaultlyApp extends StatefulWidget {
  const VaultlyApp({super.key});

  @override
  State<VaultlyApp> createState() => _VaultlyAppState();
}

class _VaultlyAppState extends State<VaultlyApp> {
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return MaterialApp.router(
          theme: state.isDark ? darkTheme : lightTheme,
          debugShowCheckedModeBanner: false,
          routerConfig: _appRouter.config(),
        );
      },
    );
  }
}
