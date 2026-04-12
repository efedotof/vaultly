import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/model/page_response.dart';
import 'package:vaulth_app/server/service/key_manager_service.dart';
import 'package:vaulth_app/server/service/logger_service.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';
import 'file_interface.dart';
import 'package:vaulth_app/server/model/file/decryption_metadata/decryption_metadata.dart';

class FileRepository implements FileInterface {
  final Dio _dio;
  final String fileAddress;
  final AuthLocalStorage authLocalStorage;
  final _logger = LoggerService();

  FileRepository({
    required this.fileAddress,
    required KeyManagerService keyManager,
    required this.authLocalStorage,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: fileAddress,
           connectTimeout: const Duration(seconds: 300),
           receiveTimeout: const Duration(seconds: 300),
         ),
       ) {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await authLocalStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            debugPrint(
              '[FileRepository] ✅ Токен установлен для ${options.uri}',
            );
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            debugPrint(
              '[FileRepository] ⚠️ Токен отсутствует для ${options.uri}',
            );
          }
          return handler.next(options);
        },
      ),
    );
  }

  @override
  Future<FileDto> uploadShps({
    required Uint8List encryptedData,
    required String originalFileName,
    String? folderId,
    required String userId,
    required String keyOwner,
    required bool isPublic,
    ProgressCallback? onSendProgress,
  }) async {
    debugPrint(
      '[FileRepository] uploadShps called: file=$originalFileName, size=${encryptedData.length} bytes',
    );
    try {
      final multipartFile = MultipartFile.fromBytes(
        encryptedData,
        filename: '$originalFileName.shps',
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
        'isPublic': isPublic ? 'true' : 'false',
        'folderId': folderId,
      });

      final response = await _dio.post(
        '/upload/shps',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: onSendProgress,
      );

      return FileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<FileDto> uploadPublicFile({
    required File file,
    String? folderId,
    ProgressCallback? onSendProgress,
  }) async {
    debugPrint('[FileRepository] uploadPublicFile called: ${file.path}');
    try {
      final fileName = file.path.split('/').last;
      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
        'folderId': folderId,
      });

      final response = await _dio.post(
        '/upload/public',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: onSendProgress,
      );

      return FileDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<PageResponse<FileDto>> getAllFiles({
    int page = 0,
    int size = 20,
  }) async {
    debugPrint('[FileRepository] getAllFiles called: page=$page, size=$size');
    try {
      final response = await _dio.get(
        '',
        queryParameters: {'page': page, 'size': size},
      );
      debugPrint('[FileRepository] getAllFiles succeeded');
      return PageResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => FileDto.fromJson(json),
      );
    } on DioException catch (e) {
      debugPrint('[FileRepository] getAllFiles error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<PageResponse<FileDto>> getRecentFiles({
    int page = 0,
    int size = 10,
  }) async {
    debugPrint(
      '[FileRepository] getRecentFiles called: page=$page, size=$size',
    );
    try {
      final response = await _dio.get(
        '/recent',
        queryParameters: {'page': page, 'size': size},
      );
      debugPrint('[FileRepository] getRecentFiles succeeded');
      return PageResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => FileDto.fromJson(json),
      );
    } on DioException catch (e) {
      debugPrint('[FileRepository] getRecentFiles error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<Uint8List> downloadShps(String fileId) async {
    _logger.debug('[FileRepository] Downloading SHPS file: $fileId');
    final response = await _dio.get(
      '/$fileId/download',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }

  @override
  Future<Uint8List> downloadDecrypted(String fileId) async {
    _logger.debug(
      '[FileRepository] Downloading decrypted content for public file: $fileId',
    );
    final response = await _dio.get(
      '/$fileId/content',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }

  @override
  Future<void> deleteFile(String fileId) async {
    _logger.debug('[FileRepository] Deleting file: $fileId');
    try {
      await _dio.delete('/$fileId');
      _logger.debug('[FileRepository] File deleted successfully');
    } on DioException catch (e) {
      _logger.error('[FileRepository] Delete file error: ${e.message}');
      throw _handleDioError(e);
    }
  }

  @override
  Future<DecryptionMetadata> getDecryptionMetadata(String fileId) async {
    _logger.debug('[FileRepository] Fetching decryption metadata for: $fileId');
    final response = await _dio.get('/$fileId/content');
    _logger.debug('[FileRepository] response: $response');
    return DecryptionMetadata.fromJson(response.data);
  }

  @override
  Future<Uint8List> downloadShpsFromUrl(String url) async {
    _logger.debug('[FileRepository] Downloading SHPS from: $url');
    final response = await Dio().get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }

  Exception _handleDioError(DioException e) {
    debugPrint(
      '[FileRepository] Dio error: ${e.message}, status: ${e.response?.statusCode}',
    );
    return Exception('Network error: ${e.message}');
  }
}
