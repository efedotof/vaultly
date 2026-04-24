import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'content_type.dart';
import 'icon_placeholder.dart';
import 'video_thumbnail_widget.dart';

class PreviewContent extends StatelessWidget {
  const PreviewContent({
    super.key,
    required this.data,
    required this.type,
    required this.fileName,
  });
  final Uint8List data;
  final ContentType type;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ContentType.image:
        return Image.memory(
          data,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return IconPlaceholder(fileName: fileName);
          },
        );
      case ContentType.markdown:
        final markdownContent = utf8.decode(data, allowMalformed: true);
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ClipRect(
              child: Markdown(
                data: markdownContent,
                selectable: false,
                padding: const EdgeInsets.all(4),
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 8),
                  h1: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      case ContentType.video:
        return VideoThumbnailWidget(data: data, fileName: fileName);
      case ContentType.text:
      case ContentType.binary:
        return IconPlaceholder(fileName: fileName);
    }
  }
}
