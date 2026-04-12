import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vaulth_app/server/model/file/upload_task/upload_task.dart';
import 'task_tile.dart';

class UploadOverlay extends StatelessWidget {
  const UploadOverlay({
    super.key,
    required this.tasks,
    required this.onRetry,
    required this.onDismiss,
  });

  final List<UploadTask> tasks;
  final void Function(String taskId) onRetry;
  final void Function(String taskId) onDismiss;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tasks
                .map(
                  (task) => TaskTile(
                    task: task,
                    onRetry: () => onRetry(task.id),
                    onDismiss: () => onDismiss(task.id),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
