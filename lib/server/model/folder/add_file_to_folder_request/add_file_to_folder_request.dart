import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_file_to_folder_request.freezed.dart';
part 'add_file_to_folder_request.g.dart';

@freezed
abstract class AddFileToFolderRequest with _$AddFileToFolderRequest {
  const factory AddFileToFolderRequest({required String fileId}) =
      _AddFileToFolderRequest;

  factory AddFileToFolderRequest.fromJson(Map<String, dynamic> json) =>
      _$AddFileToFolderRequestFromJson(json);
}
