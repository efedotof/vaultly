import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/home/cubit/home_cubit.dart';
import 'package:vaulth_app/route/app_router.dart';
import 'package:vaulth_app/server/model/folder/folder_dto/folder_dto.dart';

class FolderCard extends StatefulWidget {
  const FolderCard({super.key, required this.folder});
  final FolderDto folder;

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> {
  final TextEditingController _renameController = TextEditingController();

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onFileDroppedOnFolder(String? folderId, String? fileId) {
    if (folderId == null || fileId == null) return;
    context.read<HomeCubit>().addFileToFolder(folderId, fileId);
    _showSnackBar('Файл добавлен в папку');
  }

  void _showFolderOptions(FolderDto folder) {
    final folderId = folder.id;
    if (folderId == null) return;
    final isHidden = folder.isHidden ?? false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Переименовать'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(folder);
              },
            ),
            ListTile(
              leading: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
              title: Text(isHidden ? 'Сделать видимой' : 'Скрыть папку'),
              onTap: () {
                Navigator.pop(context);
                context.read<HomeCubit>().toggleFolderHidden(
                  folderId,
                  !isHidden,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteFolder(folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(FolderDto folder) async {
    _renameController.text = folder.name ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Переименовать папку',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _renameController,
                decoration: InputDecoration(
                  hintText: 'Новое имя',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Переименовать'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true && _renameController.text.trim().isNotEmpty) {
      if (!mounted) return;
      final folderId = folder.id;
      if (folderId == null) return;
      context.read<HomeCubit>().renameFolder(
        folderId,
        _renameController.text.trim(),
      );
    }
  }

  void _openFolder(FolderDto folder) {
    final folderId = folder.id;
    if (folderId == null) return;
    context.pushRoute(FolderRoute(folderId: folderId));
  }

  Future<void> _confirmDeleteFolder(FolderDto folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Удалить папку?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text('Папка "${folder.name}" будет удалена.'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text('Удалить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm == true) {
      if (!mounted) return;
      final folderId = folder.id;
      if (folderId == null) return;
      context.read<HomeCubit>().deleteFolder(folderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final folderId = widget.folder.id;
    final folderName = widget.folder.name ?? 'Без имени';

    return DragTarget<String>(
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _openFolder(widget.folder),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: candidateData.isNotEmpty ? 6 : 4,
                  shadowColor: Theme.of(context).colorScheme.shadow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: Colors.amber.withValues(alpha: 0.1),
                          child: Center(
                            child: Icon(
                              Icons.folder,
                              size: 64,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _showFolderOptions(widget.folder),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 140,
                child: Text(
                  folderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
      onAcceptWithDetails: (details) {
        final fileId = details.data as String?;
        _onFileDroppedOnFolder(folderId, fileId);
      },
    );
  }
}
