import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vaulth_app/app/cubit/file_upload_cubit.dart';
import 'package:vaulth_app/server/model/file/upload_task/upload_task.dart';

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

    final allCompleted = tasks.every((t) => t.status == UploadStatus.completed);
    if (allCompleted) return const SizedBox.shrink();

    UploadTask currentTask = tasks.firstWhere(
      (t) =>
          t.status != UploadStatus.completed && t.status != UploadStatus.error,
      orElse: () => tasks.firstWhere(
        (t) => t.status == UploadStatus.error,
        orElse: () => tasks.first,
      ),
    );

    final total = tasks.length;
    final currentIndex = tasks.indexOf(currentTask) + 1;

    final statusText = _getStatusText(currentTask);
    String? subtitle;
    if (currentTask.status == UploadStatus.uploading) {
      subtitle = '${(currentTask.progress * 100).toInt()}%';
    } else if (currentTask.status == UploadStatus.error) {
      subtitle = currentTask.errorMessage ?? 'Ошибка загрузки';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (total == 1)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Center(
                    child: Text(
                      '$currentIndex',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: currentTask.status == UploadStatus.error
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                    Text(
                      currentTask.fileName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(UploadTask task) {
    switch (task.status) {
      case UploadStatus.idle:
        return 'Ожидание...';
      case UploadStatus.encrypting:
        return 'Шифрование...';
      case UploadStatus.uploading:
        return 'Загрузка...';
      case UploadStatus.linking:
        return 'Сохранение...';
      case UploadStatus.completed:
        return 'Завершено';
      case UploadStatus.error:
        return 'Ошибка';
    }
  }
}
