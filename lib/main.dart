import 'package:flutter/material.dart';
import 'package:vaulth_app/app/app_initializer.dart';
import 'package:media_kit/media_kit.dart';
import 'route/app_router.dart';
import 'server/service/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final LoggerService logger = LoggerService();
  await logger.init();
  MediaKit.ensureInitialized();

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


//glass become rally stuff disorder will employ abstract dinosaur punch hawk help oppose cage shallow another conduct kite junior razor vacant wish final palm