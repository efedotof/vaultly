// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'icon_placeholder.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final Uint8List data;
  final String fileName;
  const VideoThumbnailWidget({
    super.key,
    required this.data,
    required this.fileName,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  Future<Uint8List?>? _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _generateThumbnailWeb();
    setState(() {});
  }

  Future<Uint8List?> _generateThumbnailWeb() async {
    try {
      final blob = html.Blob([widget.data], 'video/mp4');
      final url = html.Url.createObjectUrl(blob);
      final video = html.VideoElement()
        ..src = url
        ..autoplay = false
        ..muted = true
        ..style.display = 'none';
      html.document.body?.append(video);

      final completer = Completer<Uint8List?>();

      void cleanup() {
        video.remove();
        html.Url.revokeObjectUrl(url);
      }

      video.onLoadedMetadata.first
          .then((_) async {
            video.currentTime = 0;
            await video.onSeeked.first;
            await Future.delayed(const Duration(milliseconds: 100));
            final vw = video.videoWidth;
            final vh = video.videoHeight;
            if (vw != 0 && vh != 0) {
              final scale = 140 / vw;
              final drawHeight = (vh * scale).round();
              final canvas = html.CanvasElement(width: 140, height: drawHeight);
              final ctx = canvas.context2D;
              ctx.drawImageScaled(video, 0, 0, 140, drawHeight);
              final dataUrl = canvas.toDataUrl('image/jpeg', 0.75);
              final byteString = dataUrl.split(',').last;
              final bytes = base64.decode(byteString);
              completer.complete(Uint8List.fromList(bytes));
            } else {
              completer.complete(null);
            }
            cleanup();
          })
          .catchError((e) {
            cleanup();
            if (!completer.isCompleted) completer.complete(null);
          });

      return completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          cleanup();
          return null;
        },
      );
    } catch (e) {
      debugPrint('🌐 Web thumbnail error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                IconPlaceholder(fileName: widget.fileName),
          );
        }
        return IconPlaceholder(fileName: widget.fileName);
      },
    );
  }
}
