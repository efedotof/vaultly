import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vaulth_app/features/auth/cubit/auth_cubit.dart';
import 'package:vaulth_app/features/notes/cubit/note_editor_cubit.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';
import 'package:vaulth_app/server/service/key_manager_service.dart';
import 'package:vaulth_app/server/service/key_manager_service_web.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

class NoteEditorScreen extends StatefulWidget {
  final FileDto? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final dynamic keyManagerService;

  @override
  void initState() {
    super.initState();
    keyManagerService = kIsWeb ? KeyManagerServiceWeb() : KeyManagerService();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = NoteEditorCubit(
          fileRepository: context.read<FileInterface>(),
          authStorage: context.read<AuthLocalStorage>(),
          authCubit: context.read<AuthCubit>(),
          keyManager: keyManagerService,
        );
        cubit.initialize(widget.note);
        return cubit;
      },
      child: NoteEditorView(initialPreview: widget.note != null),
    );
  }
}

class NoteEditorView extends StatefulWidget {
  final bool initialPreview;
  const NoteEditorView({super.key, this.initialPreview = false});

  @override
  State<NoteEditorView> createState() => _NoteEditorViewState();
}

class _NoteEditorViewState extends State<NoteEditorView> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  late bool _isPreview;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _isPreview = widget.initialPreview;
    final cubit = context.read<NoteEditorCubit>();
    _controller.addListener(() {
      cubit.updateContent(_controller.text);
    });
    _nameController.addListener(() {
      cubit.updateNoteName(_nameController.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _togglePreview() {
    setState(() => _isPreview = !_isPreview);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NoteEditorCubit, NoteEditorState>(
      listener: (context, state) {
        state.whenOrNull(
          saved: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Заметка сохранена')));
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка: $message'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
        );
      },
      builder: (context, state) {
        state.maybeWhen(
          loaded: (note, content, noteName) {
            if (!_initialized) {
              _initialized = true;
              _controller.text = content;
              _nameController.text = noteName;
            }
          },
          orElse: () {},
        );

        return Scaffold(
          appBar: AppBar(
            title: state.maybeWhen(
              loaded: (_, _, _) => TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: 'Название заметки',
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              orElse: () => const Text('Загрузка...'),
            ),
            actions: [
              IconButton(
                icon: Icon(_isPreview ? Icons.edit : Icons.preview),
                onPressed: _togglePreview,
              ),
              if (state.maybeWhen(saving: () => true, orElse: () => false))
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    final cubit = context.read<NoteEditorCubit>();
                    cubit.state.maybeWhen(
                      loaded: (note, content, noteName) {
                        cubit.saveNote(
                          existingNote: note,
                          content: content,
                          noteName: noteName,
                        );
                      },
                      orElse: () {},
                    );
                  },
                ),
            ],
          ),
          body: state.when(
            initial: () => const SizedBox(),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (_, _, _) => _isPreview
                ? Markdown(
                    data: _controller.text,
                    selectable: true,
                    padding: const EdgeInsets.all(16),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Пишите в формате Markdown...',
                      ),
                    ),
                  ),
            saving: () => const Center(child: CircularProgressIndicator()),
            saved: () => const SizedBox(),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка: $message'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Назад'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
