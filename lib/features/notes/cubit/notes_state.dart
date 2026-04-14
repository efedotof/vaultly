part of 'notes_cubit.dart';

@freezed
class NotesState with _$NotesState {
  const factory NotesState.initial() = _Initial;
  const factory NotesState.loading() = _Loading;
  const factory NotesState.loaded(
    List<FileDto> notes,
    PageResponse<FileDto> page,
  ) = _Loaded;
  const factory NotesState.error(String message) = _Error;
}
