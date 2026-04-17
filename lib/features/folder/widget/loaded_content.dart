import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/app/cubit/file_upload_cubit.dart';
import 'package:vaulth_app/features/folder/cubit/folder_cubit.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_dto/folder_dto.dart';
import 'folder_file_card.dart';
import 'folder_file_tile.dart';

class LoadedContent extends StatefulWidget {
  const LoadedContent({
    super.key,
    required this.files,
    required this.folderId,
    this.folder,
    required this.passwordController,
    required this.isPublicUpload,
    required this.isGridView,
    required this.onToggleView,
  });
  final List<FileDto> files;
  final String folderId;
  final FolderDto? folder;
  final TextEditingController passwordController;
  final bool isPublicUpload;
  final bool isGridView;
  final VoidCallback onToggleView;

  @override
  State<LoadedContent> createState() => _LoadedContentState();
}

class _LoadedContentState extends State<LoadedContent> {
  Future<void> _uploadFileToFolder() async {
    if (!mounted) return;

    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;

    widget.passwordController.clear();
    bool isPublic = widget.isPublicUpload;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Загрузить файлы в папку',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Выбрано файлов: ${result.files.length}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: widget.passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Пароль (для приватных файлов)',
                    hintText: 'Оставьте пустым для публичных',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: isPublic,
                      onChanged: (value) {
                        setStateDialog(() {
                          isPublic = value ?? false;
                        });
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Expanded(
                      child: Text('Публичные файлы (без шифрования)'),
                    ),
                  ],
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
                      child: const Text('Загрузить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final filesBytes = <Uint8List>[];
    final fileNames = <String>[];

    for (final platformFile in result.files) {
      Uint8List bytes;
      if (kIsWeb) {
        bytes = platformFile.bytes!;
      } else {
        final file = File(platformFile.path!);
        bytes = await file.readAsBytes();
      }
      filesBytes.add(bytes);
      fileNames.add(platformFile.name);
    }

    if (!mounted) return;

    context.read<FileUploadCubit>().addMultipleUploadTasks(
      filesBytes: filesBytes,
      fileNames: fileNames,
      password: widget.passwordController.text.trim(),
      folderId: widget.folderId,
      isPublic: isPublic,
      onAllSuccess: () {
        if (!mounted) return;
        context.read<FolderCubit>().refresh();
      },
    );
  }

  void _removeFile(String fileId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Удалить файл из папки',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Удалить файл из текущей папки?'),
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
                      backgroundColor: Theme.of(context).colorScheme.error,
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

    if (confirmed == true) {
      if (!mounted) return;
      context.read<FolderCubit>().removeFileFromFolder(fileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
      child: Column(
        children: [
          if (widget.folder != null)
            Container(
              margin: const EdgeInsets.only(
                top: kToolbarHeight + 8,
                left: 16,
                right: 16,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ID: ${widget.folder!.id ?? widget.folder!.id}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: widget.files.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'В папке нет файлов',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : widget.isGridView
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      children: widget.files.map((file) {
                        return FolderFileCard(
                          file: file,
                          onRemove: () => _removeFile(file.id!),
                        );
                      }).toList(),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: widget.files.length,
                    itemBuilder: (context, index) {
                      final file = widget.files[index];
                      return FolderFileTile(
                        file: file,
                        onRemove: () => _removeFile(file.id!),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: _uploadFileToFolder,
              icon: const Icon(Icons.upload_file),
              label: const Text('Загрузить файл в папку'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
