import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/service/cache/local_file_cache.dart';
import 'content_type.dart';
import 'preview_content.dart';

class FullSizeCachedPreview extends StatefulWidget {
  final FileDto file;
  final LocalFileCache cache;

  const FullSizeCachedPreview({
    super.key,
    required this.file,
    required this.cache,
  });

  @override
  State<FullSizeCachedPreview> createState() => _FullSizeCachedPreviewState();
}

class _FullSizeCachedPreviewState extends State<FullSizeCachedPreview> {
  Future<Uint8List?>? _dataFuture;
  Future<String?>? _originalNameFuture;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final fileId = widget.file.id;
    if (fileId != null) {
      _dataFuture = widget.cache.getFileDecrypted(fileId);
      _originalNameFuture = widget.cache.getOriginalName(fileId);
    }
  }

  void _retry() {
    setState(() {
      _retryCount++;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileId = widget.file.id;
    if (fileId == null) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
        ),
      );
    }

    return FutureBuilder<Uint8List?>(
      key: ValueKey('preview_${fileId}_$_retryCount'),
      future: _dataFuture,
      builder: (context, dataSnapshot) {
        if (dataSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (dataSnapshot.hasError) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _retry();
          });
          return Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: Icon(Icons.error_outline, color: Colors.grey, size: 48),
            ),
          );
        }
        final data = dataSnapshot.data;
        if (data == null) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _retry();
          });
          return GestureDetector(
            onTap: _retry,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, color: Colors.grey, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      'Нет данных',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return FutureBuilder<String?>(
          future: _originalNameFuture,
          builder: (context, nameSnapshot) {
            final originalName = nameSnapshot.data ?? widget.file.originalName;
            final type = _detectContentType(data, originalName);
            return PreviewContent(
              data: data,
              type: type,
              fileName: originalName,
            );
          },
        );
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
    if (lowerName.endsWith('.md')) {
      return ContentType.markdown;
    }
    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.bmp')) {
      return ContentType.image;
    }

    if (lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.avi') ||
        lowerName.endsWith('.mkv') ||
        lowerName.endsWith('.webm') ||
        lowerName.endsWith('.flv') ||
        lowerName.endsWith('.wmv')) {
      return ContentType.video;
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
