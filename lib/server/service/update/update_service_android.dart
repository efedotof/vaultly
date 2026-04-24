import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vaulth_app/server/service/system/logger_service.dart';
import 'update_service.dart';
import 'update_info.dart';

class AndroidUpdateService implements IUpdateService {
  final String githubRepoUrl;
  final String _githubUser;
  final String _repoName;
  final LoggerService _logger = LoggerService();

  AndroidUpdateService({required this.githubRepoUrl})
    : _githubUser = _extractUserFromUrl(githubRepoUrl),
      _repoName = _extractRepoFromUrl(githubRepoUrl);

  static String _extractUserFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    return segments.isNotEmpty ? segments[0] : '';
  }

  static String _extractRepoFromUrl(String url) {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    return segments.length > 1 ? segments[1].replaceAll('.git', '') : '';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/$_githubUser/$_repoName/releases/latest',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      _logger.debug('GitHub API returned ${response.statusCode}');
      return null;
    } catch (e) {
      _logger.debug('Failed to fetch latest release: $e');
      return null;
    }
  }

  Map<String, dynamic>? _findApkAsset(List? assets) {
    if (assets == null) return null;
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      if (name.toLowerCase().endsWith('.apk')) {
        return asset as Map<String, dynamic>;
      }
    }
    return null;
  }

  @override
  Future<UpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) {
      _logger.debug('AndroidUpdateService: not Android, skipping');
      return null;
    }

    try {
      _logger.debug(
        'Checking for updates from GitHub: $_githubUser/$_repoName',
      );
      final latestRelease = await _fetchLatestRelease();
      if (latestRelease == null) return null;

      final version = latestRelease['tag_name'] as String? ?? 'unknown';
      final apkAsset = _findApkAsset(latestRelease['assets'] as List?);
      if (apkAsset == null) return null;

      final downloadUrl = apkAsset['browser_download_url'] as String;
      final fileSize = apkAsset['size'] as int? ?? 0;

      _logger.info('Update found: $version, size: ${_formatBytes(fileSize)}');
      return UpdateInfo(
        version: version,
        downloadUrl: downloadUrl,
        fileSize: fileSize,
      );
    } catch (e, stack) {
      _logger.error('Error checking updates', error: e, stackTrace: stack);
      return null;
    }
  }

  @override
  Future<bool> downloadAndInstall(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    if (!Platform.isAndroid) return false;
    if (await Permission.requestInstallPackages.isDenied) {
      final status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        _logger.warning('Разрешение на установку не получено');
        return false;
      }
    }

    final dir = await getExternalStorageDirectory();
    if (dir == null) return false;
    final fileName = downloadUrl.split('/').last;
    final filePath = '${dir.path}/$fileName';

    final dio = Dio();
    try {
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) onProgress(received / total);
        },
      );
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      _logger.error('Download/install failed', error: e);
      return false;
    }
  }
}
