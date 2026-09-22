part of 'folder_cubit.dart';

@freezed
class FolderState with _$FolderState {
  const factory FolderState.initial() = _Initial;
  const factory FolderState.loading() = _Loading;
  const factory FolderState.loaded({
    required String folderId,
    required List<FileDto> files,
    FolderDto? folder,
  }) = _Loaded;
  const factory FolderState.passwordRequired({
    required String folderId,
    FolderDto? folder,
    String? errorMessage,
  }) = _PasswordRequired;
  const factory FolderState.error(String message) = _Error;
  const factory FolderState.deleted() = _Deleted;
  const factory FolderState.unauthorized() = _Unauthorized;
}
