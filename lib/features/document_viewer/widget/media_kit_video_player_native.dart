import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

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
  late final Player _player;
  late final VideoController _videoController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _initVideo();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _initVideo() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final ext = widget.fileName.split('.').last;
      final file = File(
        '${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await file.writeAsBytes(widget.data);
      widget.onTempPath(file.path);

      await _player.open(Media(file.path));
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки видео: $_error',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: SizedBox.expand(
        child: Video(
          controller: _videoController,
          controls: AdaptiveVideoControls,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
