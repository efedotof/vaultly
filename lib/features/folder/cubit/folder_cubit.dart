import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/model/folder/add_file_to_folder_request/add_file_to_folder_request.dart';
import 'package:vaulth_app/server/model/folder/folder_access_dto/folder_access_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_create_dto/folder_create_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_dto/folder_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_move_dto/folder_move_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_share_dto/folder_share_dto.dart';
import 'package:vaulth_app/server/model/folder/folder_update_dto/folder_update_dto.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';
import 'package:vaulth_app/server/repository/folder/folder_interface.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

part 'folder_state.dart';
part 'folder_cubit.freezed.dart';

class FolderCubit extends Cubit<FolderState> {
  final FolderInterface folderRepository;
  final FileInterface fileRepository;
  final dynamic keyManagerService;
  final AuthLocalStorage authLocalStorage;

  FolderCubit({
    required this.folderRepository,
    required this.fileRepository,
    required this.keyManagerService,
    required this.authLocalStorage,
  }) : super(const FolderState.initial());

  Future<void> loadFolder({required String folderId, FolderDto? folder}) async {
    emit(const FolderState.loading());
    try {
      final hasAccess = await folderRepository.checkFolderAccess(
        folderId,
        const FolderAccessDto(),
      );
      if (!hasAccess) {
        emit(FolderState.passwordRequired(folderId: folderId, folder: folder));
        return;
      }
      final files = await folderRepository.getFolderFiles(folderId);
      emit(
        FolderState.loaded(folderId: folderId, files: files, folder: folder),
      );
    } catch (e) {
      if (e.toString().contains('403') || e.toString().contains('401')) {
        emit(FolderState.passwordRequired(folderId: folderId, folder: folder));
      } else {
        emit(FolderState.error(e.toString()));
      }
    }
  }

  Future<void> unlockFolder(String folderId, String password) async {
    final currentState = state;
    if (currentState is! _PasswordRequired) return;
    emit(const FolderState.loading());
    try {
      final hasAccess = await folderRepository.checkFolderAccess(
        folderId,
        FolderAccessDto(password: password),
      );
      if (!hasAccess) {
        emit(
          FolderState.passwordRequired(
            folderId: folderId,
            folder: currentState.folder,
            errorMessage: 'Неверный пароль',
          ),
        );
        return;
      }
      final files = await folderRepository.getFolderFiles(folderId);
      emit(
        FolderState.loaded(
          folderId: folderId,
          files: files,
          folder: currentState.folder,
        ),
      );
    } catch (e) {
      emit(FolderState.error(e.toString()));
    }
  }

  Future<void> refresh() async {
    await state.maybeWhen(
      loaded: (folderId, _, folder) async {
        await loadFolder(folderId: folderId, folder: folder);
      },
      passwordRequired: (folderId, folder, _) async {
        await loadFolder(folderId: folderId, folder: folder);
      },
      orElse: () {},
    );
  }

  Future<void> createFolder(String name, {String? password}) async {
    await state.maybeWhen(
      loaded: (folderId, _, folder) async {
        final previousState = state;
        emit(const FolderState.loading());
        try {
          final request = FolderCreateDto(
            name: name,
            parentFolderId: folderId,
            password: password,
          );
          await folderRepository.createFolder(request);
          await refresh();
        } catch (e) {
          emit(FolderState.error(e.toString()));
          emit(previousState);
        }
      },
      orElse: () {},
    );
  }

  Future<void> setFolderPassword(String folderId, String? password) async {
    try {
      await folderRepository.setFolderPassword(folderId, password);
    } catch (e) {
      emit(FolderState.error(e.toString()));
    }
  }

  Future<void> renameFolder(String folderIdToRename, String newName) async {
    await state.maybeWhen(
      loaded: (folderId, _, folder) async {
        final previousState = state;
        emit(const FolderState.loading());
        try {
          final request = FolderUpdateDto(name: newName);
          await folderRepository.renameFolder(folderIdToRename, request);
          await refresh();
        } catch (e) {
          emit(FolderState.error(e.toString()));
          emit(previousState);
        }
      },
      orElse: () {},
    );
  }

  Future<void> deleteFolder(String folderIdToDelete) async {
    await state.maybeWhen(
      loaded: (folderId, _, folder) async {
        final previousState = state;
        emit(const FolderState.loading());
        try {
          await folderRepository.deleteFolder(folderIdToDelete);
          if (folderIdToDelete == folderId) {
            emit(const FolderState.deleted());
          } else {
            await refresh();
          }
        } catch (e) {
          emit(FolderState.error(e.toString()));
          emit(previousState);
        }
      },
      orElse: () {},
    );
  }

  Future<void> addFileToFolder(String fileId) async {
    await state.maybeWhen(
      loaded: (folderId, _, folder) async {
        final previousState = state;
        emit(const FolderState.loading());
        try {
          final request = AddFileToFolderRequest(fileId: fileId);
          await folderRepository.addFileToFolder(folderId, request);
          await refresh();
        } catch (e) {
          emit(FolderState.error(e.toString()));
          emit(previousState);
        }
      },
      orElse: () {},
    );
  }

  Future<void> removeFileFromFolder(String fileId) async {
    await state.maybeWhen(
      loaded: (folderId, _, folder) async {
        final previousState = state;
        emit(const FolderState.loading());
        try {
          await folderRepository.removeFileFromFolder(folderId, fileId);
          await refresh();
        } catch (e) {
          emit(FolderState.error(e.toString()));
          emit(previousState);
        }
      },
      orElse: () {},
    );
  }

  Future<void> moveFiles(FolderMoveDto moveRequest) async {
    await state.maybeWhen(
      loaded: (folderId, _, folder) async {
        final previousState = state;
        emit(const FolderState.loading());
        try {
          await folderRepository.moveFiles(moveRequest);
          if (moveRequest.sourceFolderId == folderId ||
              moveRequest.targetFolderId == folderId) {
            await refresh();
          }
        } catch (e) {
          emit(FolderState.error(e.toString()));
          emit(previousState);
        }
      },
      orElse: () {},
    );
  }

  Future<List<FolderAccessDto>> shareFolder(FolderShareDto shareRequest) async {
    try {
      final result = await folderRepository.shareFolder(
        shareRequest.folderId ?? "",
        shareRequest,
      );
      return result;
    } catch (e) {
      emit(FolderState.error(e.toString()));
      rethrow;
    }
  }

  Future<void> closeFolderForOthers(String folderId) async {
    await state.maybeWhen(
      loaded: (currentFolderId, _, folder) async {
        final previousState = state;
        emit(const FolderState.loading());
        try {
          await folderRepository.closeFolderForOthers(folderId);
          if (folderId == currentFolderId) {
            await refresh();
          }
        } catch (e) {
          emit(FolderState.error(e.toString()));
          emit(previousState);
        }
      },
      orElse: () {},
    );
  }

  Future<bool> checkFolderAccess(
    String folderId,
    FolderAccessDto request,
  ) async {
    try {
      return await folderRepository.checkFolderAccess(folderId, request);
    } catch (e) {
      emit(FolderState.error(e.toString()));
      return false;
    }
  }
}
