import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/app/cubit/file_upload_cubit.dart';
import 'package:vaulth_app/features/auth/cubit/auth_cubit.dart';
import 'package:vaulth_app/features/home/cubit/batch_cache_cubit.dart';
import 'package:vaulth_app/features/home/cubit/home_cubit.dart';
import 'package:vaulth_app/features/home/widget/widget.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/model/file/upload_task/upload_task.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final TextEditingController _folderNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _folderNameController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<HomeCubit>().refresh();
  }

  Future<void> _showCreateFolderDialog() async {
    _folderNameController.clear();
    final passwordController = TextEditingController();
    bool protectWithPassword = false;

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Новая папка',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _folderNameController,
                  decoration: InputDecoration(
                    hintText: 'Название папки',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: protectWithPassword,
                      onChanged: (value) {
                        setState(() => protectWithPassword = value ?? false);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Text('Защитить паролем'),
                  ],
                ),
                if (protectWithPassword) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Введите пароль',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Theme.of(context)
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
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        final name = _folderNameController.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(context, {
                          'name': name,
                          'password': protectWithPassword
                              ? passwordController.text.trim()
                              : null,
                        });
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

    if (result != null && mounted) {
      context.read<HomeCubit>().createFolder(
        result['name']!,
        password: result['password'],
      );
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final platformFile = result.files.first;
    final fileName = platformFile.name;
    Uint8List fileBytes;

    if (kIsWeb) {
      fileBytes = platformFile.bytes!;
    } else {
      final file = File(platformFile.path!);
      fileBytes = await file.readAsBytes();
    }

    final isPublic = await _showTypeDialog();
    if (isPublic == null) return;

    final password = await _showPasswordDialog();
    if (password == null) return;

    if (!mounted) return;

    context.read<FileUploadCubit>().addUploadTask(
      fileBytes: fileBytes,
      fileName: fileName,
      password: password,
      isPublic: isPublic,
      onSuccess: () {
        context.read<HomeCubit>().refresh();
      },
    );
  }

  Future<bool?> _showTypeDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Тип файла',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Text('Выберите тип загрузки'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Публичный'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Приватный'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showPasswordDialog() async {
    TextEditingController controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Введите пароль',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ваш пароль для доступа к ключам',
                style: Theme.of(context).textTheme.bodyMedium,
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
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(controller.text),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _cacheAllFiles(BuildContext context) async {
    final homeState = context.read<HomeCubit>().state;
    final List<FileDto> allFiles = homeState.maybeWhen(
      loaded: (_, _, all) => all,
      orElse: () => [],
    );

    if (allFiles.isEmpty) {
      _showSnackBar('Нет файлов для кэширования');
      return;
    }

    final authCubit = context.read<AuthCubit>();
    String? password = authCubit.currentPassword;

    if (password == null || password.isEmpty) {
      password = await _showPasswordDialog();
      if (!mounted) return;
      if (password == null || password.isEmpty) {
        _showSnackBar('Пароль не введён', isError: true);
        return;
      }
    }
    if (context.mounted) {
      context.read<BatchCacheCubit>().cacheAllFiles(
        allFiles,
        password: password,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<BatchCacheCubit, BatchCacheState>(
        listener: (context, state) {
          state.whenOrNull(
            error: (msg) => _showSnackBar(msg, isError: true),
            completed: (cached, total) =>
                _showSnackBar('Закэшировано $cached из $total файлов'),
          );
        },
        child: Stack(
          children: [
            BlocConsumer<HomeCubit, HomeState>(
              listener: (context, state) {
                state.whenOrNull(
                  error: (message) =>
                      _showSnackBar('Ошибка: $message', isError: true),
                  folderError: (message) =>
                      _showSnackBar('Ошибка папки: $message', isError: true),
                  fileDeleteError: (message) => _showSnackBar(
                    'Ошибка удаления файла: $message',
                    isError: true,
                  ),
                  addFileError: (message) => _showSnackBar(
                    'Ошибка добавления файла: $message',
                    isError: true,
                  ),
                );
              },
              builder: (context, state) {
                return state.when(
                  initial: () =>
                      const Center(child: CircularProgressIndicator()),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  loaded: (folders, recentFiles, allFiles) => RefreshIndicator(
                    onRefresh: _refresh,
                    child: ContentWidget(
                      folders: folders,
                      recentFiles: recentFiles,
                      allFiles: allFiles,
                      scrollController: _scrollController,
                    ),
                  ),
                  error: (message) => ErrorWidgets(message: message),
                  creatingFolder: () => OverlayLoading(
                    message: 'Создание папки...',
                    scrollController: _scrollController,
                  ),
                  updatingFolder: () => OverlayLoading(
                    message: 'Обновление папки...',
                    scrollController: _scrollController,
                  ),
                  deletingFolder: () => OverlayLoading(
                    message: 'Удаление папки...',
                    scrollController: _scrollController,
                  ),
                  folderError: (message) => ErrorWidget(message),
                  deletingFile: () => OverlayLoading(
                    message: 'Удаление файла...',
                    scrollController: _scrollController,
                  ),
                  fileDeleteError: (message) => ErrorWidgets(message: message),
                  addingFileToFolder: () => OverlayLoading(
                    message: 'Добавление файла в папку...',
                    scrollController: _scrollController,
                  ),
                  addFileError: (message) => ErrorWidgets(message: message),
                );
              },
            ),

            Positioned(
              top: MediaQuery.of(context).size.height * 0.046,
              left: 24.0,
              right: 24.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Главная'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _refresh,
                            tooltip: 'Обновить',
                          ),
                          IconButton(
                            icon: const Icon(Icons.download_done),
                            onPressed: () => _cacheAllFiles(context),
                            tooltip: 'Кэшировать все файлы',
                          ),
                          IconButton(
                            icon: const Icon(Icons.cloud_upload),
                            onPressed: _uploadFile,
                            tooltip: 'Загрузить файл',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: BlocBuilder<FileUploadCubit, FileUploadState>(
                builder: (context, uploadState) {
                  final tasks = uploadState.maybeWhen(
                    uploading: (tasks) => tasks,
                    error: (_, tasks) => tasks,
                    orElse: () => <UploadTask>[],
                  );
                  final activeTasks = tasks
                      .where((t) => t.status != UploadStatus.completed)
                      .toList();
                  if (activeTasks.isEmpty) return const SizedBox.shrink();

                  return UploadOverlay(
                    tasks: activeTasks,
                    onRetry: (taskId) =>
                        context.read<FileUploadCubit>().retryTask(taskId),
                    onDismiss: (taskId) =>
                        context.read<FileUploadCubit>().dismissTask(taskId),
                  );
                },
              ),
            ),

            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: BlocBuilder<BatchCacheCubit, BatchCacheState>(
                builder: (context, state) {
                  return state.maybeWhen(
                    inProgress: (current, total) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Кэширование файлов: $current из $total'),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: current / total),
                        ],
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: _showCreateFolderDialog,
              label: const Text('Новая папка'),
              icon: const Icon(Icons.create_new_folder),
              heroTag: 'createFolder',
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              onPressed: _uploadFile,
              label: const Text('Загрузить файл'),
              icon: const Icon(Icons.cloud_upload),
              heroTag: 'uploadFile',
            ),
          ],
        ),
      ),
    );
  }
}
