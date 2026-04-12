import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/app/cubit/file_upload_cubit.dart';
import 'package:vaulth_app/features/home/widget/upload_overlay.dart';
import 'package:vaulth_app/features/profile/cubit/profile_cubit.dart';
import 'package:vaulth_app/features/profile/widget/widget.dart';
import 'package:vaulth_app/server/model/file/upload_task/upload_task.dart';

@RoutePage()
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadCurrentUser();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _refresh() {
    context.read<ProfileCubit>().loadCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocConsumer<ProfileCubit, ProfileState>(
            listener: (context, state) {
              state.whenOrNull(
                error: (message) =>
                    _showSnackBar('Ошибка: $message', isError: true),
                updateError: (message) =>
                    _showSnackBar('Ошибка обновления: $message', isError: true),
                updateSuccess: (profile) =>
                    _showSnackBar('Профиль обновлён', isError: false),
              );
            },
            builder: (context, state) {
              return state.when(
                initial: () => const Center(child: CircularProgressIndicator()),
                loading: () => const Center(child: CircularProgressIndicator()),
                loaded: (profile) => ProfileContent(
                  profile: profile,
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                  emailController: _emailController,
                ),
                error: (message) => ErrorWidgets(message: message),
                updating: () =>
                    const Center(child: CircularProgressIndicator()),
                updateSuccess: (profile) => ProfileContent(
                  profile: profile,
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                  emailController: _emailController,
                ),
                updateError: (message) => ErrorWidgets(message: message),
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
                    const Text('Профиль'),
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
    );
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
}
