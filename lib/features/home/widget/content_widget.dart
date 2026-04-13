import 'package:flutter/material.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_dto/folder_dto.dart';

import 'file_card.dart';
import 'folder_card.dart';
import 'section_header.dart';

class ContentWidget extends StatelessWidget {
  const ContentWidget({
    super.key,
    required this.folders,
    required this.recentFiles,
    required this.allFiles,
    this.cachedFiles, 
    required this.scrollController,
  });

  final List<FolderDto> folders;
  final List<FileDto> recentFiles;
  final List<FileDto> allFiles;
  final List<FileDto>? cachedFiles;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final hasServerData =
        folders.isNotEmpty || recentFiles.isNotEmpty || allFiles.isNotEmpty;
    final hasCachedData = cachedFiles != null && cachedFiles!.isNotEmpty;

    if (!hasServerData && !hasCachedData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text('Нет данных', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Нажмите "Обновить" или создайте папку',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final serverFileIds = allFiles.map((f) => f.id).toSet();
    final uniqueCachedFiles =
        cachedFiles?.where((f) => !serverFileIds.contains(f.id)).toList() ?? [];

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.1,
      ),
      children: [
        if (folders.isNotEmpty) ...[
          SectionHeader(title: 'Папки'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: folders
                  .map((folder) => FolderCard(folder: folder))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (recentFiles.isNotEmpty) ...[
          SectionHeader(title: 'Последние файлы'),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recentFiles.length,
              itemBuilder: (context, index) {
                final file = recentFiles[index];
                return FileCard(file: file);
              },
            ),
          ),
        ],
        if (allFiles.isNotEmpty) ...[
          SectionHeader(title: 'Все файлы'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: allFiles.map((file) => FileCard(file: file)).toList(),
            ),
          ),
        ],
        if (uniqueCachedFiles.isNotEmpty) ...[
          SectionHeader(title: 'Кэшированные файлы (офлайн)'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
              children: uniqueCachedFiles
                  .map((file) => FileCard(file: file))
                  .toList(),
            ),
          ),
        ],
        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
      ],
    );
  }
}
