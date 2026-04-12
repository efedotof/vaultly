import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/service/local_file_cache.dart';

import 'file_card_content.dart';

class FileCard extends StatelessWidget {
  const FileCard({super.key, required this.file});
  final FileDto file;
  @override
  Widget build(BuildContext context) {
    final localCache = context.read<LocalFileCache>();
    final fileId = file.id;
    if (fileId == null) return const SizedBox.shrink();

    return LongPressDraggable<String>(
      data: fileId,
      feedback: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Icon(Icons.insert_drive_file, color: Colors.white, size: 48),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: FileCardContent(
          file: file,
          fileId: fileId,
          localCache: localCache,
        ),
      ),
      child: FileCardContent(
        file: file,
        fileId: fileId,
        localCache: localCache,
      ),
    );
  }
}
