import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vaulth_app/app/app_initializer.dart';
import 'package:media_kit/media_kit.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'route/app_router.dart';
import 'server/service/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final LoggerService logger = LoggerService();
  await logger.init();
  MediaKit.ensureInitialized();

  if (!kIsWeb) {
    if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (Platform.isIOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }
  }
  runApp(AppInitializer(child: VaultlyApp()));
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
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _appRouter.config(),
    );
  }
}
