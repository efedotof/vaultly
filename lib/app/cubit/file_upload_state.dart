part of 'file_upload_cubit.dart';

enum UploadStatus { idle, encrypting, uploading, completed, error }

@freezed
abstract class FileUploadState with _$FileUploadState {
  const factory FileUploadState.initial() = _Initial;

  const factory FileUploadState.uploading({
    @Default([]) List<UploadTask> tasks,
  }) = _Uploading;

  const factory FileUploadState.error({
    required String message,
    @Default([]) List<UploadTask> tasks,
  }) = _UploadError;
}
