import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vaulth_app/features/notes/cubit/notes_cubit.dart';
import 'package:vaulth_app/features/notes/widget/note_editor_screen.dart';
import 'package:vaulth_app/features/notes/widget/note_list_item.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';

@RoutePage()
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesCubit, NotesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Заметки'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<NotesCubit>().refresh(),
              ),
            ],
          ),
          body: state.when(
            initial: () => const SizedBox(),
            loading: () => const Center(child: CircularProgressIndicator()),
            loaded: (notes, _) => notes.isEmpty
                ? const Center(
                    child: Text(
                      'Нет заметок. Нажмите "+" чтобы создать новую.',
                    ),
                  )
                : ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (ctx, index) {
                      final note = notes[index];
                      return NoteListItem(
                        note: note,
                        onTap: () => _openNoteEditor(context, note),
                        onDelete: () => _deleteNote(context, note),
                      );
                    },
                  ),
            error: (msg) => Center(child: Text('Ошибка: $msg')),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: FloatingActionButton.extended(
              onPressed: () => _createNewNote(context),
              label: const Text('Новая заметка'),
              icon: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  void _openNoteEditor(BuildContext context, FileDto note) {
    final cubit = context.read<NotesCubit>();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)))
        .then((_) => cubit.refresh());
  }

  void _createNewNote(BuildContext context) {
    final cubit = context.read<NotesCubit>();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NoteEditorScreen()))
        .then((_) => cubit.refresh());
  }

  void _deleteNote(BuildContext context, FileDto note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: Text('Заметка "${note.name}" будет удалена безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NotesCubit>().deleteNote(note.id!);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
