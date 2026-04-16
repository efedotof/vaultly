import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/app/cubit/file_upload_cubit.dart';
import 'package:vaulth_app/features/auth/cubit/auth_cubit.dart';
import 'package:vaulth_app/features/home/widget/upload_overlay.dart';
import 'package:vaulth_app/features/settings/cubit/settings_cubit.dart';
import 'package:vaulth_app/features/settings/widget/widget.dart';
import 'package:vaulth_app/route/app_router.dart';
import 'package:vaulth_app/server/model/file/upload_task/upload_task.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto/user_profile_dto.dart';

@RoutePage()
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfileDto? _lastProfile;
  int? _lastCacheSize;

  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadSettingsData();
  }

  Future<void> _refresh() async {
    if (!context.mounted) return;
    await context.read<SettingsCubit>().refresh();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<SettingsCubit, SettingsState>(
            listener: (context, state) {
              state.whenOrNull(
                error: (message) => _showSnackBar(message, isError: true),
                loaded: (profile, devices, cacheSizeBytes, _, _, _, _) {
                  _lastProfile = profile;
                  _lastCacheSize = cacheSizeBytes;
                },
                unauthorized: () {
                  context.replaceRoute(const AuthRoute());
                },
              );
            },
          ),
          BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              state.whenOrNull(
                unauthenticated: () {
                  _showSnackBar('Вы вышли из системы', isError: false);
                  context.replaceRoute(const AuthRoute());
                },
              );
            },
          ),
        ],
        child: Stack(
          children: [
            BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                if (state.maybeWhen(
                  initial: () => true,
                  loading: () => true,
                  orElse: () => false,
                )) {
                  return const Center(child: CircularProgressIndicator());
                }

                final errorMessage = state.maybeWhen(
                  error: (message) => message,
                  orElse: () => null,
                );
                if (errorMessage != null) {
                  return ErrorWidgets(message: errorMessage, onRetry: _refresh);
                }

                if (_lastProfile == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: SettingsList(
                    profile: _lastProfile!,
                    cacheSizeBytes: _lastCacheSize,
                  ),
                );
              },
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.046,
              left: 24.0,
              right: 24.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Настройки'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _refresh,
                            tooltip: 'Обновить',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: BlocBuilder<FileUploadCubit, FileUploadState>(
                builder: (context, uploadState) {
                  final tasks = uploadState.maybeWhen(
                    uploading: (tasks) => tasks,
                    error: (_, tasks) => tasks,
                    orElse: () => <UploadTask>[],
                  );
                  final activeTasks = tasks
                      .where((t) => t.status != UploadStatus.completed)
                      .toList();
                  if (activeTasks.isEmpty) return const SizedBox.shrink();
                  return UploadOverlay(
                    tasks: activeTasks,
                    onRetry: (taskId) =>
                        context.read<FileUploadCubit>().retryTask(taskId),
                    onDismiss: (taskId) =>
                        context.read<FileUploadCubit>().dismissTask(taskId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
