import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/service/local_file_cache.dart';

import 'content_type.dart';
import 'preview_content.dart';

class FullSizeCachedPreview extends StatelessWidget {
  final FileDto file;
  final LocalFileCache cache;

  const FullSizeCachedPreview({
    super.key,
    required this.file,
    required this.cache,
  });

  @override
  Widget build(BuildContext context) {
    final fileId = file.id;
    if (fileId == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
        ),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: cache.getFile(fileId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final data = snapshot.data;
        if (data == null) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
            ),
          );
        }

        final type = _detectContentType(data, file.originalName);
        return PreviewContent(data: data, type: type, fileName: file.name);
      },
    );
  }

  ContentType _detectContentType(Uint8List data, String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.txt') ||
        lowerName.endsWith('.json') ||
        lowerName.endsWith('.xml') ||
        lowerName.endsWith('.csv')) {
      return ContentType.text;
    }
    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.bmp')) {
      return ContentType.image;
    }
    if (data.length > 4) {
      if (data[0] == 0xFF && data[1] == 0xD8) return ContentType.image;
      if (data[0] == 0x89 &&
          data[1] == 0x50 &&
          data[2] == 0x4E &&
          data[3] == 0x47) {
        return ContentType.image;
      }
      if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46) {
        return ContentType.image;
      }
    }
    return ContentType.binary;
  }
}
