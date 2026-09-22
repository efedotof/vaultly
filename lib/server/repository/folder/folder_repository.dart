import 'package:dio/dio.dart';
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
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  @override
  Future<FolderDto> createFolder(FolderCreateDto request) async {
    try {
      final response = await _dio.post('', data: request.toJson());
      return FolderDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    try {
      await _dio.delete('/$folderId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<FolderDto> renameFolder(
    String folderId,
    FolderUpdateDto request,
  ) async {
    try {
      final response = await _dio.put('/$folderId', data: request.toJson());
      return FolderDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<FileDto> addFileToFolder(
    String folderId,
    AddFileToFolderRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/$folderId/files',
        data: request.toJson(),
      );
      return FileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<FileDto>> moveFiles(FolderMoveDto request) async {
    try {
      final response = await _dio.post('/move', data: request.toJson());
      final list = response.data as List;
      return list
          .map((item) => FileDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<FileDto> removeFileFromFolder(String folderId, String fileId) async {
    try {
      final response = await _dio.delete('/$folderId/files/$fileId');
      return FileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<FolderDto> closeFolderForOthers(String folderId) async {
    try {
      final response = await _dio.post('/$folderId/close');
      return FolderDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<FolderAccessDto>> shareFolder(
    String folderId,
    FolderShareDto request,
  ) async {
    try {
      final dtoWithId = request.copyWith(folderId: folderId);
      final response = await _dio.post(
        '/$folderId/share',
        data: dtoWithId.toJson(),
      );
      final list = response.data as List;
      return list
          .map((item) => FolderAccessDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<bool> checkFolderAccess(
    String folderId,
    FolderAccessDto request,
  ) async {
    try {
      final dtoWithId = request.copyWith(folderId: folderId);
      final response = await _dio.post(
        '/$folderId/access/check',
        data: dtoWithId.toJson(),
      );
      final hasAccess = response.data as bool;
      return hasAccess;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        return false;
      }
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<FolderDto>> getFolderTree() async {
    try {
      final response = await _dio.get('/tree');
      final list = response.data as List;
      return list
          .map((item) => FolderDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<FileDto>> getFolderFiles(String folderId) async {
    try {
      final response = await _dio.get('/$folderId/files');
      final list = response.data as List;
      return list
          .map((item) => FileDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<FolderDto> updateFolder(
    String folderId,
    FolderUpdateDto request,
  ) async {
    try {
      final response = await _dio.put('/$folderId', data: request.toJson());
      return FolderDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> setFolderPassword(String folderId, String? password) async {
    try {
      await _dio.post('/$folderId/password', data: {'password': password});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    return Exception('Network error: ${e.message}');
  }
}
