import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vaulth_app/app/cubit/file_upload_cubit.dart';

part 'upload_task.freezed.dart';

@freezed
abstract class UploadTask with _$UploadTask {
  const factory UploadTask({
    required String id,
    required String fileName,
    @Default(UploadStatus.idle) UploadStatus status,
    @Default(0.0) double progress,
    String? errorMessage,
    String? folderId,
  }) = _UploadTask;
}
