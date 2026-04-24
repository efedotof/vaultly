import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/home/widget/file_and_preview/file_icon_helper.dart';
import 'package:vaulth_app/features/home/widget/file_and_preview/full_size_cached_preview.dart';
import 'package:vaulth_app/route/app_router.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/service/cache/local_file_cache.dart';

class FolderFileCard extends StatelessWidget {
  const FolderFileCard({super.key, required this.file, required this.onRemove});

  final FileDto file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final localCache = context.read<LocalFileCache>();
    final fileId = file.id;
    if (fileId == null) return const SizedBox.shrink();

    final fileName = file.name;

    return GestureDetector(
      onTap: () => context.pushRoute(DocumentViewerRoute(file: file)),
      child: Container(
        width: 140,
        height: 180,
        margin: const EdgeInsets.all(6),
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shadowColor: Theme.of(context).colorScheme.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 140,
                child: FutureBuilder<bool>(
                  future: localCache.hasFile(fileId),
                  builder: (context, snapshot) {
                    final isCached = snapshot.data == true;
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: isCached
                              ? FullSizeCachedPreview(
                                  file: file,
                                  cache: localCache,
                                )
                              : Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: Center(
                                    child: Icon(
                                      getIconByExtension(fileName),
                                      size: 48,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: onRemove,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
