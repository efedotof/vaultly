import 'package:vaulth_app/server/model/file/check_duplicate_request.dart';
import 'package:vaulth_app/server/model/file/decryption_metadata.dart';
import 'package:vaulth_app/server/model/file/file_dto.dart';
import 'package:vaulth_app/server/model/file/link_file_request.dart';

abstract interface class FileInterface {
  Future<FileDto> uploadShps({
    required String filePath,
    required String fileName,
    required bool isPublic,
    String? folderId,
    String? contentHash,
  });

  Future<FileDto> uploadPublicFile({
    required String filePath,
    required String fileName,
    String? folderId,
    String? contentHash,
  });

  Future<Map<String, dynamic>> getAllFiles({int page = 0, int size = 20});

  Future<Map<String, dynamic>> getRecentFiles({int page = 0, int size = 10});

  Future<String> downloadFile({required String fileId});

  Future<DecryptionMetadata> getDecryptionMetadata({required String fileId});

  Future<void> deleteFile({required String fileId});

  Future<Map<String, dynamic>> getNotes({int page = 0, int size = 20});

  Future<FileDto> createNote({
    required String filePath,
    required String fileName,
    String? folderId,
  });

  Future<FileDto> updateNoteContent({
    required String noteId,
    required String filePath,
    required String fileName,
  });

  Future<bool> checkDuplicate({required CheckDuplicateRequest request});

  Future<FileDto> linkExistingFile({required LinkFileRequest request});
}
