import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:vaulth_app/server/model/file/decryption_metadata/decryption_metadata.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/model/page_response.dart';

abstract class FileInterface {
  Future<FileDto> uploadShps({
    required Uint8List encryptedData,
    required String originalFileName,
    String? folderId,
    required String userId,
    required String keyOwner,
    required bool isPublic,
    ProgressCallback? onSendProgress,
  });

  Future<FileDto> uploadPublicFile({
    required File file,
    String? folderId,
    ProgressCallback? onSendProgress,
  });

  Future<PageResponse<FileDto>> getAllFiles({int page = 0, int size = 20});
  Future<PageResponse<FileDto>> getRecentFiles({int page = 0, int size = 10});

  Future<Uint8List> downloadShps(String fileId);

  Future<Uint8List> downloadDecrypted(String fileId);
  Future<void> deleteFile(String fileId);

  Future<DecryptionMetadata> getDecryptionMetadata(String fileId);
  Future<Uint8List> downloadShpsFromUrl(String url);
}
