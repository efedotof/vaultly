import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:vaulth_app/storage/auth_local_storage.dart';
import 'folder_interface.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/model/folder/add_file_to_folder_request/add_file_to_folder_request.dart';
import 'package:vaulth_app/server/model/folder/folder_access_dto/folder_access_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_create_dto/folder_create_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_dto/folder_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_move_dto/folder_move_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_share_dto/folder_share_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_update_dto/folder_update_dto.dart';

class FolderRepository implements FolderInterface {
  final Dio _dio;
  final String folderAddress;
  final AuthLocalStorage authLocalStorage;

  FolderRepository({
    required this.folderAddress,
    required this.authLocalStorage,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: folderAddress,
           connectTimeout: const Duration(seconds: 3000),
           receiveTimeout: const Duration(seconds: 3000),
         ),
       ) {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await authLocalStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            debugPrint(
              '[FolderRepository] ✅ Токен установлен для ${options.uri}',
            );
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            debugPrint(
              '[FolderRepository] ⚠️ Токен отсутствует для ${options.uri}',
            );
          }
          return handler.next(options);
        },
      ),
    );
  }

  @override
  Future<FolderDto> createFolder(FolderCreateDto request) async {
    debugPrint('[FolderRepository] createFolder called: name=${request.name}');
    try {
      final response = await _dio.post('', data: request.toJson());
      debugPrint(
        '[FolderRepository] createFolder succeeded, id=${(response.data as Map)['id']}',
      );
      return FolderDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[FolderRepository] createFolder error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    debugPrint('[FolderRepository] deleteFolder called: folderId=$folderId');
    try {
      await _dio.delete('/$folderId');
      debugPrint('[FolderRepository] deleteFolder succeeded');
    } on DioException catch (e) {
      debugPrint('[FolderRepository] deleteFolder error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<FolderDto> renameFolder(
    String folderId,
    FolderUpdateDto request,
  ) async {
    debugPrint(
      '[FolderRepository] renameFolder called: folderId=$folderId, newName=${request.name}',
    );
    try {
      final response = await _dio.put('/$folderId', data: request.toJson());
      debugPrint('[FolderRepository] renameFolder succeeded');
      return FolderDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[FolderRepository] renameFolder error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<FileDto> addFileToFolder(
    String folderId,
    AddFileToFolderRequest request,
  ) async {
    debugPrint(
      '[FolderRepository] addFileToFolder called: folderId=$folderId, fileId=${request.fileId}',
    );
    try {
      final response = await _dio.post(
        '/$folderId/files',
        data: request.toJson(),
      );
      debugPrint('[FolderRepository] addFileToFolder succeeded');
      return FileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[FolderRepository] addFileToFolder error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<FileDto>> moveFiles(FolderMoveDto request) async {
    debugPrint(
      '[FolderRepository] moveFiles called: sourceFolderId=${request.sourceFolderId}, targetFolderId=${request.targetFolderId}, fileIds=${request.fileIds}',
    );
    try {
      final response = await _dio.post('/move', data: request.toJson());
      final list = response.data as List;
      debugPrint(
        '[FolderRepository] moveFiles succeeded, moved ${list.length} files',
      );
      return list
          .map((item) => FileDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[FolderRepository] moveFiles error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<FileDto> removeFileFromFolder(String folderId, String fileId) async {
    debugPrint(
      '[FolderRepository] removeFileFromFolder called: folderId=$folderId, fileId=$fileId',
    );
    try {
      final response = await _dio.delete('/$folderId/files/$fileId');
      debugPrint('[FolderRepository] removeFileFromFolder succeeded');
      return FileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[FolderRepository] removeFileFromFolder error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<FolderDto> closeFolderForOthers(String folderId) async {
    debugPrint(
      '[FolderRepository] closeFolderForOthers called: folderId=$folderId',
    );
    try {
      final response = await _dio.post('/$folderId/close');
      debugPrint('[FolderRepository] closeFolderForOthers succeeded');
      return FolderDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[FolderRepository] closeFolderForOthers error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<FolderAccessDto>> shareFolder(
    String folderId,
    FolderShareDto request,
  ) async {
    debugPrint('[FolderRepository] shareFolder called: folderId=$folderId');
    try {
      final dtoWithId = request.copyWith(folderId: folderId);
      final response = await _dio.post(
        '/$folderId/share',
        data: dtoWithId.toJson(),
      );
      final list = response.data as List;
      debugPrint(
        '[FolderRepository] shareFolder succeeded, shared with ${list.length} users',
      );
      return list
          .map((item) => FolderAccessDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[FolderRepository] shareFolder error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<bool> checkFolderAccess(
    String folderId,
    FolderAccessDto request,
  ) async {
    debugPrint(
      '[FolderRepository] checkFolderAccess called: folderId=$folderId, userId=${request.password}',
    );
    try {
      final dtoWithId = request.copyWith(folderId: folderId);
      final response = await _dio.post(
        '/$folderId/access/check',
        data: dtoWithId.toJson(),
      );
      final hasAccess = response.data as bool;
      debugPrint('[FolderRepository] checkFolderAccess result: $hasAccess');
      return hasAccess;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        debugPrint(
          '[FolderRepository] checkFolderAccess denied (status ${e.response?.statusCode})',
        );
        return false;
      }
      debugPrint('[FolderRepository] checkFolderAccess error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<FolderDto>> getFolderTree() async {
    debugPrint('[FolderRepository] getFolderTree called');
    try {
      final response = await _dio.get('/tree');
      final list = response.data as List;
      debugPrint(
        '[FolderRepository] getFolderTree succeeded, count: ${list.length}',
      );
      return list
          .map((item) => FolderDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[FolderRepository] getFolderTree error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<FileDto>> getFolderFiles(String folderId) async {
    debugPrint('[FolderRepository] getFolderFiles called: folderId=$folderId');
    try {
      final response = await _dio.get('/$folderId/files');
      final list = response.data as List;
      debugPrint(
        '[FolderRepository] getFolderFiles succeeded, count: ${list.length}',
      );
      return list
          .map((item) => FileDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[FolderRepository] getFolderFiles error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<FolderDto> updateFolder(
    String folderId,
    FolderUpdateDto request,
  ) async {
    debugPrint('[FolderRepository] updateFolder called: folderId=$folderId');
    try {
      final response = await _dio.put('/$folderId', data: request.toJson());
      debugPrint('[FolderRepository] updateFolder succeeded');
      return FolderDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[FolderRepository] updateFolder error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> setFolderPassword(String folderId, String? password) async {
    debugPrint(
      '[FolderRepository] setFolderPassword called: folderId=$folderId',
    );
    try {
      await _dio.post('/$folderId/password', data: {'password': password});
      debugPrint('[FolderRepository] setFolderPassword succeeded');
    } on DioException catch (e) {
      debugPrint('[FolderRepository] setFolderPassword error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    debugPrint(
      '[FolderRepository] Dio error: ${e.message}, status: ${e.response?.statusCode}',
    );
    return Exception('Network error: ${e.message}');
  }
}
