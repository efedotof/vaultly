import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vaulth_app/features/document_viewer/cubit/document_viewer_cubit.dart';
import 'package:vaulth_app/features/notes/widget/note_editor_screen.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';

import 'code_view.dart';
import 'media_kit_video_player.dart';
import 'office_viewer.dart';
import 'pdf_viewer.dart';

class ContentView extends StatelessWidget {
  const ContentView({
    super.key,
    required this.data,
    required this.fileName,
    required this.type,
    required this.isFullscreen,
    required this.onPdfTempPath,
    required this.onVideoTempPath,
    this.onToggleFullscreen,
    this.onUserInteraction,
    required this.preUrlFile,
    this.file,
  });

  final Uint8List data;
  final String fileName;
  final ContentType type;
  final bool isFullscreen;
  final void Function(String path) onPdfTempPath;
  final void Function(String path) onVideoTempPath;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onUserInteraction;
  final String preUrlFile;
  final FileDto? file;

  @override
  Widget build(BuildContext context) {
    final topMargin = isFullscreen ? 0.0 : kToolbarHeight;

    switch (type) {
      case ContentType.text:
        return Container(
          margin: EdgeInsets.only(top: topMargin),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                onUserInteraction?.call();
              }
              return false;
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                utf8.decode(data, allowMalformed: true),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        );

      case ContentType.code:
        return CodeView(
          data: data,
          fileName: fileName,
          isFullscreen: isFullscreen,
          onToggleFullscreen: onToggleFullscreen,
          onUserInteraction: onUserInteraction,
        );

      case ContentType.image:
        return Container(
          margin: EdgeInsets.only(top: topMargin),
          child: Center(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(data),
            ),
          ),
        );

      case ContentType.pdf:
        return PdfViewer(data: data, onTempPath: onPdfTempPath);

      case ContentType.video:
        return MediaKitVideoPlayer(
          data: data,
          fileName: fileName,
          onTempPath: onVideoTempPath,
          isFullscreen: isFullscreen,
          onToggleFullscreen: onToggleFullscreen,
        );

      case ContentType.office:
        return Padding(
          padding: EdgeInsets.only(top: topMargin),
          child: OfficeViewer(
            data: data,
            fileName: fileName,
            publicUrl: preUrlFile,
          ),
        );

      case ContentType.binary:
        return Padding(
          padding: EdgeInsets.only(top: topMargin),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insert_drive_file,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Предпросмотр данного типа файла не поддерживается',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      case ContentType.markdown:
        return MarkdownPreview(
          data: data,
          fileName: fileName,
          file: file,
          isFullscreen: isFullscreen,
          onToggleFullscreen: onToggleFullscreen,
          onUserInteraction: onUserInteraction,
        );
    }
  }
}

class MarkdownPreview extends StatelessWidget {
  final Uint8List data;
  final String fileName;
  final FileDto? file;
  final bool isFullscreen;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onUserInteraction;

  const MarkdownPreview({
    super.key,
    required this.data,
    required this.fileName,
    required this.file,
    required this.isFullscreen,
    this.onToggleFullscreen,
    this.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final content = utf8.decode(data, allowMalformed: true);
    final topMargin = isFullscreen ? 0.0 : kToolbarHeight;

    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(top: topMargin),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                onUserInteraction?.call();
              }
              return false;
            },
            child: Markdown(
              data: content,
              selectable: true,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              if (file != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NoteEditorScreen(note: file!),
                  ),
                );
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Редактировать'),
          ),
        ),
      ],
    );
  }
}
