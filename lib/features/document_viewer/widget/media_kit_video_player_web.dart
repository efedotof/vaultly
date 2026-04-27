// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

class MediaKitVideoPlayer extends StatefulWidget {
  final Uint8List data;
  final String fileName;
  final void Function(String path) onTempPath;
  final bool isFullscreen;
  final VoidCallback? onToggleFullscreen;

  const MediaKitVideoPlayer({
    super.key,
    required this.data,
    required this.fileName,
    required this.onTempPath,
    this.isFullscreen = false,
    this.onToggleFullscreen,
  });

  @override
  State<MediaKitVideoPlayer> createState() => _MediaKitVideoPlayerState();
}

class _MediaKitVideoPlayerState extends State<MediaKitVideoPlayer> {
  html.IFrameElement? _iframe;
  String? _objectUrl;

  @override
  void initState() {
    super.initState();
    final blob = html.Blob([widget.data], 'video/mp4');
    _objectUrl = html.Url.createObjectUrl(blob);

    _iframe = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..src = _objectUrl!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Регистрируем view для HtmlElementView
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'video_player_${widget.hashCode}',
        (int viewId) => _iframe!,
      );
      setState(() {});
    });

    widget.onTempPath(_objectUrl!);
  }

  @override
  void dispose() {
    if (_objectUrl != null) {
      html.Url.revokeObjectUrl(_objectUrl!);
    }
    _iframe?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_iframe == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return HtmlElementView(viewType: 'video_player_${widget.hashCode}');
  }
}
