import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/app/cubit/file_upload_cubit.dart';
import 'package:vaulth_app/server/model/file/upload_task/upload_task.dart';

import 'task_tile.dart';

class UploadOverlay extends StatelessWidget {
  const UploadOverlay({super.key, required this.tasks});
  final List<UploadTask> tasks;
  @override
  Widget build(BuildContext context) {
    final activeTasks = tasks
        .where((t) => t.status != UploadStatus.completed)
        .toList();
    if (activeTasks.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Material(
          elevation: 8,
          shadowColor: Theme.of(context).colorScheme.shadow,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: activeTasks
                  .map(
                    (task) => TaskTile(
                      task: task,
                      onRetry: () =>
                          context.read<FileUploadCubit>().retryTask(task.id),
                      onDismiss: () =>
                          context.read<FileUploadCubit>().dismissTask(task.id),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
