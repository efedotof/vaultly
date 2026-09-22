import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/model/folder/add_file_to_folder_request/add_file_to_folder_request.dart';
import 'package:vaulth_app/server/model/folder/folder_access_dto/folder_access_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_create_dto/folder_create_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_dto/folder_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_move_dto/folder_move_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_share_dto/folder_share_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_update_dto/folder_update_dto.dart';

abstract class FolderInterface {
  Future<FolderDto> createFolder(FolderCreateDto request);
  Future<void> deleteFolder(String folderId);
  Future<FolderDto> renameFolder(String folderId, FolderUpdateDto request);
  Future<FileDto> addFileToFolder(
    String folderId,
    AddFileToFolderRequest request,
  );
  Future<List<FileDto>> moveFiles(FolderMoveDto request);
  Future<FileDto> removeFileFromFolder(String folderId, String fileId);
  Future<FolderDto> closeFolderForOthers(String folderId);
  Future<List<FolderAccessDto>> shareFolder(
    String folderId,
    FolderShareDto request,
  );
  Future<bool> checkFolderAccess(String folderId, FolderAccessDto request);
  Future<List<FolderDto>> getFolderTree();
  Future<List<FileDto>> getFolderFiles(String folderId);
  Future<FolderDto> updateFolder(String folderId, FolderUpdateDto request);
  Future<void> setFolderPassword(String folderId, String? password);
}
