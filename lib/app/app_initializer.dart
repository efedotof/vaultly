import 'package:flutter/material.dart';
import 'package:vaulth_app/app/app_repository.dart';

import 'app_bloc.dart';
import 'app_modal.dart';

class AppInitializer extends StatelessWidget {
  const AppInitializer({
    super.key,
    required this.child,
    required this.appModel,
  });
  final Widget child;
  final AppModel appModel;
  @override
  Widget build(BuildContext context) {
    return AppRepository(
      appModal: appModel,
      child: AppBloc(appModel: appModel, child: child),
    );
  }
}
