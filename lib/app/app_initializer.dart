import 'package:flutter/material.dart';
import 'package:vaulth_app/app/app_repository.dart';

import 'app_bloc.dart';

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppRepository(child: AppBloc(child: child));
  }
}
