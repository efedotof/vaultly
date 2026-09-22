import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_docs_viewer/easy_docs_viewer.dart';

class OfficeViewer extends StatefulWidget {
  final Uint8List data;
  final String fileName;
  final String? publicUrl;

  const OfficeViewer({
    super.key,
    required this.data,
    required this.fileName,
    this.publicUrl,
  });

  @override
  State<OfficeViewer> createState() => _OfficeViewerState();
}

class _OfficeViewerState extends State<OfficeViewer> {
  bool _isCheckingUrl = true;
  bool _isUrlAccessible = false;

  @override
  void initState() {
    super.initState();
    _checkPublicUrl();
  }

  Future<void> _checkPublicUrl() async {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!isMobile || widget.publicUrl == null || widget.publicUrl!.isEmpty) {
      _setUrlAccessible(false);
      return;
    }

    try {
      final response = await http.head(Uri.parse(widget.publicUrl!));
      _setUrlAccessible(
        response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (_) {
      _setUrlAccessible(false);
    }
  }

  void _setUrlAccessible(bool accessible) {
    if (!mounted) return;
    setState(() {
      _isUrlAccessible = accessible;
      _isCheckingUrl = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingUrl) {
      return const Center(child: CircularProgressIndicator());
    }

    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (isMobile && _isUrlAccessible) {
      return EasyDocsViewer(url: widget.publicUrl!);
    }

    return _ExternalOfficeViewer(data: widget.data, fileName: widget.fileName);
  }
}

class _ExternalOfficeViewer extends StatelessWidget {
  final Uint8List data;
  final String fileName;

  const _ExternalOfficeViewer({required this.data, required this.fileName});

  Future<void> _openExternally(BuildContext context) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(data);

      final result = await OpenFilex.open(file.path);
      if (!context.mounted) return;

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось открыть файл: ${result.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              fileName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Предпросмотр документов Office недоступен внутри приложения.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Открыть в другом приложении'),
              onPressed: () => _openExternally(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
