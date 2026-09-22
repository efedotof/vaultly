import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/app/cubit/file_upload_cubit.dart';
import 'package:vaulth_app/features/folder/cubit/folder_cubit.dart';
import 'package:vaulth_app/features/folder/widget/widget.dart';
import 'package:vaulth_app/route/app_router.dart';
import 'package:vaulth_app/server/model/folder/folder_access_dto/folder_access_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_move_dto/folder_move_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_share_dto/folder_share_dto.dart';

@RoutePage()
class FolderScreen extends StatefulWidget {
  final String folderId;

  const FolderScreen({
    super.key,
    @PathParam('folderId') required this.folderId,
  });

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final _nameController = TextEditingController();
  final _newNameController = TextEditingController();
  final _targetFolderIdController = TextEditingController();
  final _shareEmailController = TextEditingController();
  final _shareRoleController = TextEditingController();
  final _checkEmailController = TextEditingController();
  final _checkRoleController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isPublicUpload = false;

  bool _isGridView = true;

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<FolderCubit>().loadFolder(folderId: widget.folderId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newNameController.dispose();
    _targetFolderIdController.dispose();
    _shareEmailController.dispose();
    _shareRoleController.dispose();
    _checkEmailController.dispose();
    _checkRoleController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<String?> _showRenameDialog(String currentName) async {
    _newNameController.text = currentName;
    return showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Переименовать папку',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _newNameController,
                decoration: InputDecoration(
                  labelText: 'Новое имя',
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _newNameController.text.trim()),
                    child: const Text('Переименовать'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<FolderMoveDto?> _showMoveFilesDialog() async {
    _targetFolderIdController.clear();
    return showDialog<FolderMoveDto>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Переместить файлы',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _targetFolderIdController,
                decoration: InputDecoration(
                  labelText: 'ID целевой папки',
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
              const SizedBox(height: 8),
              Text(
                'Перемещение будет выполнено для всех файлов текущей папки',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      final targetId = _targetFolderIdController.text.trim();
                      if (targetId.isNotEmpty) {
                        Navigator.pop(
                          context,
                          FolderMoveDto(
                            sourceFolderId: widget.folderId,
                            targetFolderId: targetId,
                            fileIds: [],
                          ),
                        );
                      }
                    },
                    child: const Text('Переместить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<FolderShareDto?> _showShareDialog() async {
    _shareEmailController.clear();
    _shareRoleController.clear();
    return showDialog<FolderShareDto>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Поделиться папкой',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _shareEmailController,
                decoration: InputDecoration(
                  labelText: 'Email пользователя',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _shareRoleController,
                decoration: InputDecoration(
                  labelText: 'Роль (viewer/editor)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      final email = _shareEmailController.text.trim();
                      final role = _shareRoleController.text.trim();
                      if (email.isNotEmpty && role.isNotEmpty) {
                        Navigator.pop(
                          context,
                          FolderShareDto(folderId: widget.folderId),
                        );
                      }
                    },
                    child: const Text('Поделиться'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<FolderAccessDto?> _showCheckAccessDialog() async {
    _checkEmailController.clear();
    _checkRoleController.clear();
    return showDialog<FolderAccessDto>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Проверить доступ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _checkEmailController,
                decoration: InputDecoration(
                  labelText: 'Email пользователя',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _checkRoleController,
                decoration: InputDecoration(
                  labelText: 'Роль (viewer/editor)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      final email = _checkEmailController.text.trim();
                      final role = _checkRoleController.text.trim();
                      if (email.isNotEmpty && role.isNotEmpty) {
                        Navigator.pop(context, FolderAccessDto());
                      }
                    },
                    child: const Text('Проверить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setFolderPassword() async {
    final passwordController = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Защита папки паролем',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Введите новый пароль (оставьте пустым, чтобы убрать защиту):',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
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
                    onPressed: () =>
                        Navigator.pop(context, passwordController.text.trim()),
                    child: const Text('Сохранить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      await context.read<FolderCubit>().setFolderPassword(
        widget.folderId,
        result.isEmpty ? null : result,
      );
      _showSnackBar('Пароль обновлён');
      _refresh();
    }
  }

  Future<void> _createFolder() async {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    bool protectWithPassword = false;

    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
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
                  'Создать папку',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Имя папки',
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
                      labelText: 'Пароль',
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
                        final name = nameController.text.trim();
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
      context.read<FolderCubit>().createFolder(
        result['name']!,
        password: result['password'],
      );
    }
  }

  void _renameCurrentFolder() async {
    final state = context.read<FolderCubit>().state;
    final currentName = state.maybeWhen(
      loaded: (_, _, folder) => folder?.name ?? '',
      passwordRequired: (_, folder, _) => folder?.name ?? '',
      orElse: () => '',
    );
    if (currentName.isEmpty) return;

    final newName = await _showRenameDialog(currentName);
    if (newName != null && newName.isNotEmpty) {
      if (!mounted) return;
      context.read<FolderCubit>().renameFolder(widget.folderId, newName);
    }
  }

  void _deleteFolder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Удалить папку',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Вы уверены, что хотите удалить эту папку?'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Удалить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      context.read<FolderCubit>().deleteFolder(widget.folderId);
    }
  }

  void _moveFiles() async {
    final moveRequest = await _showMoveFilesDialog();
    if (moveRequest != null) {
      if (!mounted) return;
      context.read<FolderCubit>().moveFiles(moveRequest);
    }
  }

  void _shareFolder() async {
    final shareRequest = await _showShareDialog();
    if (shareRequest != null) {
      if (!mounted) return;
      try {
        final result = await context.read<FolderCubit>().shareFolder(
          shareRequest,
        );

        if (!mounted) return;
        _showSnackBar('Доступ предоставлен: ${result.length} записей');
      } catch (e) {
        if (!mounted) return;
        _showSnackBar('Ошибка: $e', isError: true);
      }
    }
  }

  void _closeFolderForOthers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Закрыть доступ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Закрыть доступ к папке для всех других пользователей?',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      context.read<FolderCubit>().closeFolderForOthers(widget.folderId);
    }
  }

  void _checkAccess() async {
    final accessRequest = await _showCheckAccessDialog();
    if (accessRequest != null) {
      if (!mounted) return;
      final hasAccess = await context.read<FolderCubit>().checkFolderAccess(
        widget.folderId,
        accessRequest,
      );

      if (!mounted) return;
      _showSnackBar(
        hasAccess ? 'Доступ разрешён' : 'Доступ запрещён',
        isError: !hasAccess,
      );
    }
  }

  void _refresh() {
    context.read<FolderCubit>().refresh();
  }

  String _getTitle(FolderState state) {
    return state.maybeWhen(
      loaded: (_, _, folder) => folder?.name ?? 'Папка',
      passwordRequired: (_, folder, _) => folder?.name ?? 'Защищённая папка',
      orElse: () => 'Папка',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: BlocBuilder<FolderCubit, FolderState>(
          builder: (context, state) => Text(_getTitle(state)),
        ),
        elevation: 0,
        scrolledUnderElevation: 4,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleView,
            tooltip: _isGridView ? 'Список' : 'Сетка',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Обновить',
          ),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _renameCurrentFolder();
                  break;
                case 'delete':
                  _deleteFolder();
                  break;
                case 'move':
                  _moveFiles();
                  break;
                case 'share':
                  _shareFolder();
                  break;
                case 'close':
                  _closeFolderForOthers();
                  break;
                case 'check':
                  _checkAccess();
                  break;
                case 'password':
                  _setFolderPassword();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Text('Переименовать папку'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Удалить папку'),
              ),
              const PopupMenuItem(
                value: 'move',
                child: Text('Переместить файлы'),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Text('Поделиться папкой'),
              ),
              const PopupMenuItem(
                value: 'close',
                child: Text('Закрыть доступ'),
              ),
              const PopupMenuItem(
                value: 'check',
                child: Text('Проверить доступ'),
              ),
              const PopupMenuItem(
                value: 'password',
                child: Text('Установить пароль'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          BlocConsumer<FolderCubit, FolderState>(
            listener: (context, state) {
              state.whenOrNull(
                error: (message) => _showSnackBar(message, isError: true),
                deleted: () {
                  _showSnackBar('Папка удалена');
                  Future.delayed(const Duration(seconds: 1), () {
                    if (context.mounted) Navigator.of(context).pop();
                  });
                },
                unauthorized: () {
                  context.replaceRoute(const AuthRoute());
                },
              );
            },
            builder: (context, state) {
              return state.when(
                initial: () => const Center(child: CircularProgressIndicator()),
                loading: () => const Center(child: CircularProgressIndicator()),
                loaded: (folderId, files, folder) => LoadedContent(
                  folderId: folderId,
                  files: files,
                  folder: folder,
                  passwordController: _passwordController,
                  isPublicUpload: isPublicUpload,
                  isGridView: _isGridView,
                  onToggleView: _toggleView,
                ),
                passwordRequired: (folderId, folder, errorMessage) =>
                    PasswordRequired(
                      folderId: folderId,
                      errorMessage: errorMessage,
                    ),
                error: (message) =>
                    ErrorsWidgets(message: message, folderId: widget.folderId),
                deleted: () => DeletedWidgets(),
                unauthorized: () =>
                    const Center(child: CircularProgressIndicator()),
              );
            },
          ),
          BlocBuilder<FileUploadCubit, FileUploadState>(
            builder: (context, uploadState) {
              return uploadState.maybeWhen(
                uploading: (tasks) => tasks.isNotEmpty
                    ? UploadOverlay(tasks: tasks)
                    : const SizedBox.shrink(),
                error: (_, tasks) => tasks.isNotEmpty
                    ? UploadOverlay(tasks: tasks)
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: BlocBuilder<FolderCubit, FolderState>(
          builder: (context, state) {
            return state.maybeWhen(
              loaded: (_, _, _) => FloatingActionButton.extended(
                onPressed: _createFolder,
                label: const Text('Новая папка'),
                icon: const Icon(Icons.create_new_folder),
                heroTag: 'createFolder',
              ),
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
