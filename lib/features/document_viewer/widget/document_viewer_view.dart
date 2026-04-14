import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vaulth_app/features/document_viewer/cubit/document_viewer_cubit.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/model/tempaccess/create_temp_link_request/create_temp_link_request.dart';
import 'package:vaulth_app/server/repository/temp_access/temp_access_interface.dart';
import 'package:vaulth_app/server/service/local_file_cache.dart';

import 'content_view.dart';

class DocumentViewerView extends StatefulWidget {
  final FileDto file;
  const DocumentViewerView({super.key, required this.file});

  @override
  State<DocumentViewerView> createState() => _DocumentViewerViewState();
}

class _DocumentViewerViewState extends State<DocumentViewerView> {
  static const _inactivityDuration = Duration(seconds: 3);

  bool _passwordRequested = false;
  String? _tempVideoPath;
  String? _tempPdfPath;
  late final DocumentViewerCubit _cubit;
  bool _isFullscreen = false;
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();

    _cubit = context.read<DocumentViewerCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCacheAndLoad();
    });
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _startInactivityTimer() {
    if (!mounted) return;
    _cancelInactivityTimer();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (!_isFullscreen && mounted) {
        _setFullscreen(true);
      }
    });
  }

  void _resetInactivityTimer() {
    if (!_isFullscreen) {
      _startInactivityTimer();
    }
  }

  void _setFullscreen(bool fullscreen) {
    if (_isFullscreen == fullscreen) return;
    setState(() {
      _isFullscreen = fullscreen;
    });
    if (fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _cancelInactivityTimer();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _startInactivityTimer();
    }
  }

  void _toggleFullscreen() {
    _setFullscreen(!_isFullscreen);
  }

  @override
  void dispose() {
    _cancelInactivityTimer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _deleteTempFile(_tempVideoPath);
    _deleteTempFile(_tempPdfPath);
    super.dispose();
  }

  Future<void> _deleteTempFile(String? path) async {
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> _checkCacheAndLoad() async {
    if (!mounted) return;

    final localCache = context.read<LocalFileCache>();
    final hasCached = await localCache.hasFile(widget.file.id!);
    if (!mounted) return;

    if (widget.file.isPublic == true) {
      _cubit.loadFile(file: widget.file, password: '');
      return;
    }

    if (hasCached) {
      _cubit.loadFile(file: widget.file, password: '');
    } else {
      if (_passwordRequested) return;
      _passwordRequested = true;
      _showPasswordDialog();
    }
  }

  Future<void> _showPasswordDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Введите пароль',
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Пароль для расшифровки ключа',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Пароль',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    ctx,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, controller.text),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (result != null && result.isNotEmpty) {
      _cubit.loadFile(file: widget.file, password: result);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showCreateTempLinkDialog() async {
    final expiresDaysController = TextEditingController(text: '7');
    final maxDownloadsController = TextEditingController();
    final passwordController = TextEditingController();
    bool usePassword = false;

    final result = await showDialog<CreateTempLinkRequest>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Создать временную ссылку',
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: expiresDaysController,
                  decoration: InputDecoration(
                    labelText: 'Срок действия (дней)',
                    hintText: 'например, 7',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxDownloadsController,
                  decoration: InputDecoration(
                    labelText: 'Макс. кол-во скачиваний',
                    hintText: 'оставьте пустым для безлимита',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Theme.of(ctx).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: usePassword,
                      onChanged: (v) =>
                          setState(() => usePassword = v ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Text('Защитить паролем'),
                  ],
                ),
                if (usePassword) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Theme.of(ctx)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        final days = int.tryParse(
                          expiresDaysController.text.trim(),
                        );
                        if (days == null || days <= 0) {
                          _showSnackBar(
                            ctx,
                            'Введите корректное число дней',
                            isError: true,
                          );
                          return;
                        }
                        final maxDownloads =
                            maxDownloadsController.text.trim().isNotEmpty
                            ? int.tryParse(maxDownloadsController.text.trim())
                            : null;
                        final password = usePassword
                            ? passwordController.text.trim()
                            : null;
                        if (usePassword &&
                            (password == null || password.isEmpty)) {
                          _showSnackBar(ctx, 'Введите пароль', isError: true);
                          return;
                        }

                        final request = CreateTempLinkRequest(
                          fileId: widget.file.id!,
                          expiresAt: DateTime.now().add(Duration(days: days)),
                          maxDownloads: maxDownloads,
                          password: password,
                        );
                        Navigator.pop(ctx, request);
                      },
                      child: const Text('Создать'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      await _createTempLink(result);
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _createTempLink(CreateTempLinkRequest request) async {
    try {
      final tempRepo = context.read<TempAccessInterface>();
      final response = await tempRepo.createTempLink(request);
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Временная ссылка создана',
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: QrImageView(
                    data: response.accessUrl,
                    version: QrVersions.auto,
                    size: 200.0,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Действует до: ${_formatDateTime(response.expiresAt)}'),
                if (response.maxDownloads != null)
                  Text(
                    'Осталось скачиваний: ${response.maxDownloads! - response.downloadsCount}',
                  ),
                if (request.password != null)
                  const Text('Ссылка защищена паролем'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: response.accessUrl),
                        );
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Ссылка скопирована в буфер обмена'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Копировать ссылку'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Закрыть'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(context, 'Ошибка: ${e.toString()}', isError: true);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveFileToUserLocation() async {
    final state = _cubit.state;
    final loadedData = state.mapOrNull(
      loaded: (loadedState) =>
          (data: loadedState.data, fileName: loadedState.fileName),
    );

    if (loadedData == null) {
      _showSnackBar(context, 'Файл ещё не загружен', isError: true);
      return;
    }

    final data = loadedData.data;
    final fileName = loadedData.fileName;

    try {
      if (kIsWeb) {
        final String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Сохранить файл',
          fileName: fileName,
          bytes: data,
        );
        if (outputPath == null) {
          return;
        }
        if (mounted) {
          _showSnackBar(context, 'Файл сохранён: $fileName');
        }
      } else {
        final String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Сохранить файл',
          fileName: fileName,
        );
        if (outputPath == null) {
          return;
        }
        final file = File(outputPath);
        await file.writeAsBytes(data);
        if (mounted) {
          _showSnackBar(context, 'Файл сохранён: $outputPath');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, 'Ошибка сохранения: $e', isError: true);
      }
    }
  }

  Future<void> _saveToDownloads() async {
    try {
      await context.read<DocumentViewerCubit>().downloadFile();
      if (mounted) {
        _showSnackBar(context, 'Файл сохранён в папку Загрузки');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, 'Ошибка сохранения: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _isFullscreen
          ? null
          : AppBar(
              title: Text(widget.file.originalName),
              elevation: 0,
              scrolledUnderElevation: 4,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: _toggleFullscreen,
                  tooltip: 'Полноэкранный режим',
                ),
                IconButton(
                  icon: const Icon(Icons.save_alt),
                  onPressed: _saveToDownloads,
                  tooltip: 'Сохранить в Загрузки',
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _saveFileToUserLocation,
                  tooltip: 'Сохранить как...',
                ),
                if (widget.file.isPublic == true)
                  IconButton(
                    icon: const Icon(Icons.link),
                    onPressed: _showCreateTempLinkDialog,
                    tooltip: 'Создать временную ссылку',
                  ),
              ],
            ),
      body: GestureDetector(
        onTap: () {
          if (_isFullscreen) {
            _toggleFullscreen();
          } else {
            _resetInactivityTimer();
          }
        },
        onDoubleTap: _toggleFullscreen,
        behavior: HitTestBehavior.translucent,
        child: BlocConsumer<DocumentViewerCubit, DocumentViewerState>(
          listener: (context, state) {
            state.maybeWhen(
              loaded: (_, _, _) {
                _startInactivityTimer();
              },
              error: (message) {
                _showSnackBar(context, message, isError: true);
              },
              orElse: () {},
            );
          },
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox(),
              loading: () => const Center(child: CircularProgressIndicator()),
              decrypting: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Расшифровка файла...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              downloading: () => const Center(child: Text("Загрузка файла...")),
              loaded: (data, fileName, contentType) => ContentView(
                data: data,
                fileName: fileName,
                type: contentType,
                isFullscreen: _isFullscreen,
                onPdfTempPath: (path) => _tempPdfPath = path,
                onVideoTempPath: (path) => _tempVideoPath = path,
                onToggleFullscreen: _toggleFullscreen,
                preUrlFile: widget.file.s3Url ?? "",
                file: widget.file, 
              ),
              error: (message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ошибка: $message',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Повторить'),
                        onPressed: () {
                          context.read<DocumentViewerCubit>().retry();
                        },
                      ),
                      if (widget.file.isPublic != true) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.lock),
                          label: const Text('Ввести пароль заново'),
                          onPressed: () {
                            setState(() => _passwordRequested = false);
                            _checkCacheAndLoad();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
