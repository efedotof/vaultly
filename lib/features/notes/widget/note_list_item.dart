import 'package:flutter/material.dart';
import 'package:vaulth_app/features/home/widget/file_and_preview/full_size_cached_preview.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/service/cache/local_file_cache_platform.dart';

class NoteListItem extends StatelessWidget {
  final FileDto note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final LocalFileCache cache;

  const NoteListItem({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
    required this.cache,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            width: double.infinity,
            child: FullSizeCachedPreview(file: note, cache: cache),
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: Text(note.name),
            subtitle: Text(
              '${_formatDate(note.createdAt)}  •  ${_formatSize(note.size)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
            onTap: onTap,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
