import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/model/folder/add_file_to_folder_request/add_file_to_folder_request.dart';
import 'package:vaulth_app/server/model/folder/folder_create_dto/folder_create_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_dto/folder_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_update_dto/folder_update_dto.dart';
import 'package:vaulth_app/server/model/page_response.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';
import 'package:vaulth_app/server/repository/folder/folder_interface.dart';
import 'package:vaulth_app/server/service/cache/local_file_cache_platform.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

part 'home_state.dart';
part 'home_cubit.freezed.dart';

class HomeCubit extends Cubit<HomeState> {
  final FileInterface fileRepository;
  final FolderInterface folderRepository;
  final dynamic keyManagerService;
  final AuthLocalStorage authLocalStorage;
  final LocalFileCache localFileCache;

  HomeCubit({
    required this.fileRepository,
    required this.folderRepository,
    required this.keyManagerService,
    required this.authLocalStorage,
    required this.localFileCache,
  }) : super(const HomeState.initial());

  Future<void> loadData() async {
    emit(const HomeState.loading());
    try {
      final foldersFuture = folderRepository.getFolderTree();
      final recentFuture = fileRepository.getRecentFiles(page: 0, size: 10);
      final allFuture = fileRepository.getAllFiles(page: 0, size: 50);

      final results = await Future.wait([
        foldersFuture,
        recentFuture,
        allFuture,
      ]);

      final List<FolderDto> folders = results[0] as List<FolderDto>;
      final PageResponse<FileDto> recentFilesPage =
          results[1] as PageResponse<FileDto>;
      final PageResponse<FileDto> allFilesPage =
          results[2] as PageResponse<FileDto>;

      emit(
        HomeState.loaded(
          folders: folders,
          recentFiles: recentFilesPage.content,
          allFiles: allFilesPage.content,
          cachedFiles: const [],
        ),
      );

      _loadCacheInBackground();
    } catch (e) {
      try {
        if (_is403Error(e)) {
          emit(const HomeState.unauthorized());
          return;
        }

        final cachedMeta = await localFileCache.getAllCachedFileMetadata();
        if (cachedMeta.isNotEmpty) {
          final cachedFileDtos = await _mapCachedMetaToDtoWithPauses(
            cachedMeta,
          );
          emit(
            HomeState.loaded(
              folders: const [],
              recentFiles: const [],
              allFiles: const [],
              cachedFiles: cachedFileDtos,
            ),
          );
          return;
        }
      } catch (_) {}
      emit(HomeState.error(e.toString()));
    }
  }

  Future<void> _loadCacheInBackground() async {
    try {
      final cachedMeta = await localFileCache.getAllCachedFileMetadata();
      final cachedFileDtos = await _mapCachedMetaToDtoWithPauses(cachedMeta);

      final currentState = state;
      if (currentState is _Loaded) {
        emit(currentState.copyWith(cachedFiles: cachedFileDtos));
      }
    } catch (e) {
      if (_is403Error(e)) {
        emit(const HomeState.unauthorized());
        return;
      }
    }
  }

  Future<List<FileDto>> _mapCachedMetaToDtoWithPauses(
    List<Map<String, dynamic>> cachedMeta,
  ) async {
    final List<FileDto> result = [];
    for (int i = 0; i < cachedMeta.length; i++) {
      final meta = cachedMeta[i];
      result.add(
        FileDto(
          id: meta['id'] as String,
          name: meta['originalName'] as String,
          originalName: meta['originalName'] as String,
          size: 0,
          mimeType: 'application/octet-stream',
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            meta['timestamp'] as int,
          ),
        ),
      );
      if (i % 10 == 0) {
        await Future.delayed(Duration.zero);
      }
    }
    return result;
  }

  Future<void> refresh() => loadData();

  Future<void> createFolder(
    String name, {
    String? parentFolderId,
    String? password,
  }) async {
    try {
      emit(const HomeState.creatingFolder());
      final request = FolderCreateDto(
        name: name,
        parentFolderId: parentFolderId,
        isHidden: false,
        password: password,
      );
      await folderRepository.createFolder(request);
      await loadData();
    } catch (e) {
      if (_is403Error(e)) {
        emit(const HomeState.unauthorized());
        return;
      }
      emit(HomeState.folderError(e.toString()));
      final current = state;
      if (current is _Loaded) {
        emit(current);
      } else {
        emit(HomeState.error(e.toString()));
      }
    }
  }

  Future<void> renameFolder(String folderId, String newName) async {
    try {
      emit(const HomeState.updatingFolder());
      final request = FolderUpdateDto(name: newName);
      await folderRepository.updateFolder(folderId, request);
      await loadData();
    } catch (e) {
      if (_is403Error(e)) {
        emit(const HomeState.unauthorized());
        return;
      }
      emit(HomeState.folderError(e.toString()));
      final current = state;
      if (current is _Loaded) emit(current);
    }
  }

  Future<void> toggleFolderHidden(String folderId, bool isHidden) async {
    try {
      emit(const HomeState.updatingFolder());
      final request = FolderUpdateDto(isHidden: isHidden);
      await folderRepository.updateFolder(folderId, request);
      await loadData();
    } catch (e) {
      if (_is403Error(e)) {
        emit(const HomeState.unauthorized());
        return;
      }
      emit(HomeState.folderError(e.toString()));
      final current = state;
      if (current is _Loaded) emit(current);
    }
  }

  Future<void> deleteFolder(String folderId) async {
    try {
      emit(const HomeState.deletingFolder());
      await folderRepository.deleteFolder(folderId);
      await loadData();
    } catch (e) {
      if (_is403Error(e)) {
        emit(const HomeState.unauthorized());
        return;
      }
      emit(HomeState.folderError(e.toString()));
      final current = state;
      if (current is _Loaded) emit(current);
    }
  }

  Future<void> addFileToFolder(String folderId, String fileId) async {
    try {
      emit(const HomeState.addingFileToFolder());
      final request = AddFileToFolderRequest(fileId: fileId);
      await folderRepository.addFileToFolder(folderId, request);
      await loadData();
    } catch (e) {
      if (_is403Error(e)) {
        emit(const HomeState.unauthorized());
        return;
      }
      emit(HomeState.addFileError(e.toString()));
      final current = state;
      if (current is _Loaded) emit(current);
    }
  }

  bool _is403Error(Object e) {
    final errorString = e.toString();
    return errorString.contains('403') ||
        errorString.contains('status code of 403') ||
        (e is Exception && errorString.contains('Network error'));
  }

  Future<void> deleteFile(String fileId) async {
    final prevState = state;
    if (prevState is! _Loaded) return;

    try {
      emit(const HomeState.deletingFile());
      await fileRepository.deleteFile(fileId);
      await localFileCache.deleteFile(fileId);

      final updatedRecent = prevState.recentFiles
          .where((f) => f.id != fileId)
          .toList();
      final updatedAll = prevState.allFiles
          .where((f) => f.id != fileId)
          .toList();
      final updatedCached =
          prevState.cachedFiles?.where((f) => f.id != fileId).toList() ?? [];

      emit(
        prevState.copyWith(
          recentFiles: updatedRecent,
          allFiles: updatedAll,
          cachedFiles: updatedCached,
        ),
      );
      _loadDataInBackground();
    } catch (e) {
      if (_is403Error(e)) {
        emit(const HomeState.unauthorized());
        return;
      }
      emit(HomeState.fileDeleteError(e.toString()));
      emit(prevState);
    }
  }

  Future<void> _loadDataInBackground() async {
    try {
      final foldersFuture = folderRepository.getFolderTree();
      final recentFuture = fileRepository.getRecentFiles(page: 0, size: 10);
      final allFuture = fileRepository.getAllFiles(page: 0, size: 50);

      final results = await Future.wait([
        foldersFuture,
        recentFuture,
        allFuture,
      ]);

      final folders = results[0] as List<FolderDto>;
      final recentFiles = (results[1] as PageResponse<FileDto>).content;
      final allFiles = (results[2] as PageResponse<FileDto>).content;

      final currentState = state;
      if (currentState is _Loaded) {
        emit(
          currentState.copyWith(
            folders: folders,
            recentFiles: recentFiles,
            allFiles: allFiles,
          ),
        );
      }
      _loadCacheInBackground();
    } catch (_) {}
  }
}
