import 'package:get/get_connect.dart';
import 'package:vaulth_app/server/model/file/file_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_access_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_create_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_move_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_share_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_update_dto.dart';
import 'package:vaulth_app/server/model/page_dto.dart';
import 'package:vaulth_app/server/repository/folder/folder_interface.dart';

class FolderRepository extends GetConnect implements FolderInterface {
  @override
  Future<FileDto> addFileToFolder(String folderId, String fileId) {
    // TODO: implement addFileToFolder
    throw UnimplementedError();
  }

  @override
  Future<bool> checkFolderAccess(String folderId, FolderAccessDto request) {
    // TODO: implement checkFolderAccess
    throw UnimplementedError();
  }

  @override
  Future<FolderDto> closeFolderForOthers(String folderId) {
    // TODO: implement closeFolderForOthers
    throw UnimplementedError();
  }

  @override
  Future<FolderDto> createFolder(FolderCreateDto request) {
    // TODO: implement createFolder
    throw UnimplementedError();
  }

  @override
  Future<void> deleteFolder(String folderId) {
    // TODO: implement deleteFolder
    throw UnimplementedError();
  }

  @override
  Future<PageDto<FileDto>> getFolderFiles(
    String folderId, {
    int page = 0,
    int size = 50,
  }) {
    // TODO: implement getFolderFiles
    throw UnimplementedError();
  }

  @override
  Future<List<FolderDto>> getFolderTree() {
    // TODO: implement getFolderTree
    throw UnimplementedError();
  }

  @override
  Future<List<FileDto>> moveFiles(FolderMoveDto request) {
    // TODO: implement moveFiles
    throw UnimplementedError();
  }

  @override
  Future<FileDto> removeFileFromFolder(String folderId, String fileId) {
    // TODO: implement removeFileFromFolder
    throw UnimplementedError();
  }

  @override
  Future<FolderDto> renameFolder(String folderId, FolderUpdateDto request) {
    // TODO: implement renameFolder
    throw UnimplementedError();
  }

  @override
  Future<void> setFolderPassword(String folderId, String? password) {
    // TODO: implement setFolderPassword
    throw UnimplementedError();
  }

  @override
  Future<List<FolderAccessDto>> shareFolder(
    String folderId,
    FolderShareDto request,
  ) {
    // TODO: implement shareFolder
    throw UnimplementedError();
  }
}
