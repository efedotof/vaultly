import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/model/page_response.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';

part 'notes_state.dart';
part 'notes_cubit.freezed.dart';

class NotesCubit extends Cubit<NotesState> {
  final FileInterface fileRepository;

  NotesCubit({required this.fileRepository})
    : super(const NotesState.initial()) {
    loadNotes();
  }

  Future<void> loadNotes({int page = 0, int size = 20}) async {
    emit(const NotesState.loading());
    try {
      final pageResponse = await fileRepository.getNotes(
        page: page,
        size: size,
      );
      emit(NotesState.loaded(pageResponse.content, pageResponse));
    } catch (e) {
      if (_is403Error(e)) {
        emit(const NotesState.unauthorized());
        return;
      }
      emit(NotesState.error(e.toString()));
    }
  }

  bool _is403Error(Object e) {
    final errorString = e.toString();
    return errorString.contains('403') ||
        errorString.contains('status code of 403') ||
        (e is Exception && errorString.contains('Network error'));
  }

  Future<void> refresh() => loadNotes();

  Future<void> deleteNote(String noteId) async {
    try {
      await fileRepository.deleteFile(noteId);
      await loadNotes();
    } catch (e) {
      if (_is403Error(e)) {
        emit(const NotesState.unauthorized());
        return;
      }
      emit(NotesState.error(e.toString()));
      await loadNotes();
    }
  }

  void reset() {
    emit(const NotesState.initial());
  }
}
