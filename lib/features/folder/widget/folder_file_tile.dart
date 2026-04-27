import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/home/widget/file_and_preview/file_icon_helper.dart';
import 'package:vaulth_app/features/home/widget/file_and_preview/full_size_cached_preview.dart';
import 'package:vaulth_app/route/app_router.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/service/cache/local_file_cache_platform.dart';

class FolderFileTile extends StatelessWidget {
  const FolderFileTile({super.key, required this.file, required this.onRemove});

  final FileDto file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final localCache = context.read<LocalFileCache>();
    final fileId = file.id;
    if (fileId == null) return const SizedBox.shrink();

    final fileName = file.name;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<bool>(
              future: localCache.hasFile(fileId),
              builder: (context, snapshot) {
                final isCached = snapshot.data == true;
                if (isCached) {
                  return FullSizeCachedPreview(file: file, cache: localCache);
                }
                return Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    getIconByExtension(fileName),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ),
        ),
        title: Text(
          fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.remove_circle_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: onRemove,
          tooltip: 'Удалить из папки',
        ),
        onTap: () => context.pushRoute(DocumentViewerRoute(file: file)),
      ),
    );
  }
}
