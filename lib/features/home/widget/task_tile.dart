import 'package:flutter/material.dart';
import 'package:vaulth_app/app/cubit/file_upload_cubit.dart';
import 'package:vaulth_app/server/model/file/upload_task/upload_task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onRetry,
    required this.onDismiss,
  });

  final UploadTask task;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    String statusText;
    IconData statusIcon;
    Color statusColor;

    switch (task.status) {
      case UploadStatus.idle:
        statusText = 'Ожидание...';
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.grey;
        break;
      case UploadStatus.encrypting:
        statusText = 'Шифрование...';
        statusIcon = Icons.lock;
        statusColor = Colors.blue;
        break;
      case UploadStatus.uploading:
        statusText = 'Отправка ${(task.progress * 100).toStringAsFixed(0)}%';
        statusIcon = Icons.cloud_upload;
        statusColor = Colors.orange;
        break;
      case UploadStatus.linking:
        statusText = 'Создание ссылки...';
        statusIcon = Icons.link;
        statusColor = Colors.blueGrey;
        break;
      case UploadStatus.completed:
        statusText = 'Завершено';
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case UploadStatus.error:
        statusText = 'Ошибка: ${task.errorMessage ?? "Неизвестно"}';
        statusIcon = Icons.error;
        statusColor = Colors.red;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.fileName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (task.status == UploadStatus.uploading) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: statusColor.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 4,
                    ),
                  ),
                ],
                if (task.status == UploadStatus.error) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Повторить'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onDismiss,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Закрыть'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
