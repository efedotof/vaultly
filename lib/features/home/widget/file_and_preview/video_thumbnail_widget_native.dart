import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart'; 
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
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
    _thumbnailFuture = _generateThumbnailNative();
    setState(() {});
  }

  Future<Uint8List?> _generateThumbnailNative() async {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return await _generateWithVideoThumbnail();
    } else {
      return await _generateWithFFmpeg(); // теперь будет работать!
    }
  }

  Future<Uint8List?> _generateWithVideoThumbnail() async {
    File? videoFile;
    try {
      final tempDir = await getTemporaryDirectory();
      videoFile = File(
        '${tempDir.path}/temp_video_thumb_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await videoFile.writeAsBytes(widget.data);

      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 140,
        quality: 75,
        timeMs: 0,
      );
      return thumbnail;
    } catch (e) {
      debugPrint('📱 VideoThumbnail error: $e');
      return null;
    } finally {
      await videoFile?.delete();
    }
  }

  Future<Uint8List?> _generateWithFFmpeg() async {
    File? videoFile;
    File? outputFile;
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      videoFile = File('${tempDir.path}/temp_video_$timestamp.mp4');
      outputFile = File('${tempDir.path}/thumb_$timestamp.jpg');
      await videoFile.writeAsBytes(widget.data);

      final command =
          '-i "${videoFile.path}" -ss 00:00:00.000 -vframes 1 -vf "scale=140:-2" -q:v 4 "${outputFile.path}"';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode) && await outputFile.exists()) {
        final bytes = await outputFile.readAsBytes();
        return bytes;
      } else {
        final output = await session.getOutput();
        debugPrint('🖥️ FFmpeg error: $output');
      }
      return null;
    } catch (e) {
      debugPrint('🖥️ FFmpeg exception: $e');
      return null;
    } finally {
      await videoFile?.delete();
      await outputFile?.delete();
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
