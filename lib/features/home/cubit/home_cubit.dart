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
import 'package:vaulth_app/storage/auth_local_storage.dart';

part 'home_state.dart';
part 'home_cubit.freezed.dart';

class HomeCubit extends Cubit<HomeState> {
  final FileInterface fileRepository;
  final FolderInterface folderRepository;
  final dynamic keyManagerService;
  final AuthLocalStorage authLocalStorage;

  HomeCubit({
    required this.fileRepository,
    required this.folderRepository,
    required this.keyManagerService,
    required this.authLocalStorage,
  }) : super(const HomeState.initial());

  Future<void> loadData() async {
    emit(const HomeState.loading());
    try {
      final List<FolderDto> folders = await folderRepository.getFolderTree();
      final PageResponse<FileDto> recentFilesPage = await fileRepository
          .getRecentFiles(page: 0, size: 10);
      final PageResponse<FileDto> allFilesPage = await fileRepository
          .getAllFiles(page: 0, size: 50);
      emit(
        HomeState.loaded(
          folders: folders,
          recentFiles: recentFilesPage.content,
          allFiles: allFilesPage.content,
        ),
      );
    } catch (e) {
      emit(HomeState.error(e.toString()));
    }
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
      emit(HomeState.addFileError(e.toString()));
      final current = state;
      if (current is _Loaded) emit(current);
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      emit(const HomeState.deletingFile());
      await fileRepository.deleteFile(fileId);
      await loadData();
    } catch (e) {
      emit(HomeState.fileDeleteError(e.toString()));
      final current = state;
      if (current is _Loaded) {
        emit(current);
      } else {
        emit(HomeState.error(e.toString()));
      }
    }
  }
}
