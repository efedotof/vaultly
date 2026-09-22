part of 'home_cubit.dart';

@freezed
class HomeState with _$HomeState {
  const factory HomeState.initial() = _Initial;
  const factory HomeState.loading() = _Loading;
  const factory HomeState.loaded({
    required List<FolderDto> folders,
    required List<FileDto> recentFiles,
    required List<FileDto> allFiles,
    List<FileDto>? cachedFiles,
  }) = _Loaded;
  const factory HomeState.error(String message) = _Error;
  const factory HomeState.creatingFolder() = _CreatingFolder;
  const factory HomeState.updatingFolder() = _UpdatingFolder;
  const factory HomeState.deletingFolder() = _DeletingFolder;
  const factory HomeState.folderError(String message) = _FolderError;
  const factory HomeState.deletingFile() = _DeletingFile;
  const factory HomeState.fileDeleteError(String message) = _FileDeleteError;
  const factory HomeState.addingFileToFolder() = _AddingFileToFolder;
  const factory HomeState.addFileError(String message) = _AddFileError;
  const factory HomeState.unauthorized() = _Unauthorized;
}
