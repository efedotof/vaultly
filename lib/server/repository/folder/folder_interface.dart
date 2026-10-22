import 'package:vaulth_app/server/model/file/file_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_access_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_create_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_move_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_share_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_update_dto.dart';
import 'package:vaulth_app/server/model/page_dto.dart';

abstract interface class FolderInterface {
  Future<FolderDto> createFolder(FolderCreateDto request);

  Future<void> deleteFolder(String folderId);

  Future<FolderDto> renameFolder(String folderId, FolderUpdateDto request);

  Future<FileDto> addFileToFolder(String folderId, String fileId);

  Future<List<FileDto>> moveFiles(FolderMoveDto request);

  Future<FileDto> removeFileFromFolder(String folderId, String fileId);

  Future<FolderDto> closeFolderForOthers(String folderId);

  Future<List<FolderAccessDto>> shareFolder(
    String folderId,
    FolderShareDto request,
  );

  Future<bool> checkFolderAccess(String folderId, FolderAccessDto request);

  Future<List<FolderDto>> getFolderTree();

  Future<PageDto<FileDto>> getFolderFiles(
    String folderId, {
    int page = 0,
    int size = 50,
  });

  Future<void> setFolderPassword(String folderId, String? password);
}
