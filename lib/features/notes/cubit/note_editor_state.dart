part of 'note_editor_cubit.dart';

@freezed
abstract class NoteEditorState with _$NoteEditorState {
  const factory NoteEditorState.initial() = _Initial;
  const factory NoteEditorState.loading() = _Loading;
  const factory NoteEditorState.loaded({
    required FileDto? note,
    required String content,
    required String noteName,
  }) = _Loaded;
  const factory NoteEditorState.saving() = _Saving;
  const factory NoteEditorState.saved() = _Saved;
  const factory NoteEditorState.error(String message) = _Error;
}
