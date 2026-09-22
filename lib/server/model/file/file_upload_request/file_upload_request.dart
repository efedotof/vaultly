import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;

part 'file_upload_request.freezed.dart';

@freezed
abstract class FileUploadRequest with _$FileUploadRequest {
  const factory FileUploadRequest({
    required http.MultipartFile file,
    int? folderId,
    bool? encrypt,
    String? encryptionPassword,
  }) = _FileUploadRequest;
}
