import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:bloc/bloc.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:vaulth_app/server/model/file/upload_task/upload_task.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';
import 'package:vaulth_app/server/service/shirm_encryption_service_web.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';
import 'package:shirm_crypto/shirm_crypto.dart';
import 'dart:io' as io;

part 'file_upload_state.dart';
part 'file_upload_cubit.freezed.dart';

class _TaskRetryData {
  final Uint8List fileBytes;
  final String fileName;
  final String password;
  final String? folderId;
  final bool isPublic;
  final ui.VoidCallback? onSuccess;

  _TaskRetryData({
    required this.fileBytes,
    required this.fileName,
    required this.password,
    this.folderId,
    required this.isPublic,
    this.onSuccess,
  });
}

class _PendingUploadTask {
  final String taskId;
  final Uint8List fileBytes;
  final String fileName;
  final String password;
  final String? folderId;
  final bool isPublic;
  final ui.VoidCallback? onSuccess;

  _PendingUploadTask({
    required this.taskId,
    required this.fileBytes,
    required this.fileName,
    required this.password,
    this.folderId,
    required this.isPublic,
    this.onSuccess,
  });
}

class FileUploadCubit extends Cubit<FileUploadState> {
  final FileInterface fileRepository;
  final dynamic keyManagerService;
  final AuthLocalStorage authLocalStorage;

  final Map<String, _TaskRetryData> _retryData = {};
  final List<_PendingUploadTask> _pendingTasks = [];
  bool _isProcessing = false;

  FileUploadCubit({
    required this.fileRepository,
    required this.keyManagerService,
    required this.authLocalStorage,
  }) : super(const FileUploadState.initial());

  String _calculateSha256(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> addUploadTask({
    required Uint8List fileBytes,
    required String fileName,
    required String password,
    String? folderId,
    required bool isPublic,
    ui.VoidCallback? onSuccess,
  }) async {
    final taskId =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    _addPendingTask(
      _PendingUploadTask(
        taskId: taskId,
        fileBytes: fileBytes,
        fileName: fileName,
        password: password,
        folderId: folderId,
        isPublic: isPublic,
        onSuccess: onSuccess,
      ),
    );
  }

  Future<void> addMultipleUploadTasks({
    required List<Uint8List> filesBytes,
    required List<String> fileNames,
    required String password,
    String? folderId,
    required bool isPublic,
    ui.VoidCallback? onAllSuccess,
  }) async {
    if (filesBytes.length != fileNames.length) {
      throw ArgumentError('filesBytes and fileNames must have same length');
    }

    for (int i = 0; i < filesBytes.length; i++) {
      final taskId = '${DateTime.now().millisecondsSinceEpoch}_$i';
      _addPendingTask(
        _PendingUploadTask(
          taskId: taskId,
          fileBytes: filesBytes[i],
          fileName: fileNames[i],
          password: password,
          folderId: folderId,
          isPublic: isPublic,
          onSuccess: i == filesBytes.length - 1 ? onAllSuccess : null,
        ),
      );
    }
  }

  Future<void> retryTask(String taskId) async {
    final data = _retryData[taskId];
    if (data == null) return;

    dismissTask(taskId);
    _retryData.remove(taskId);

    final newTaskId = '${DateTime.now().millisecondsSinceEpoch}_retry';
    _addPendingTask(
      _PendingUploadTask(
        taskId: newTaskId,
        fileBytes: data.fileBytes,
        fileName: data.fileName,
        password: data.password,
        folderId: data.folderId,
        isPublic: data.isPublic,
        onSuccess: data.onSuccess,
      ),
    );
  }

  void dismissTask(String taskId) {
    _removeTask(taskId);
  }

  void clearError() {
    state.maybeWhen(
      error: (message, tasks) {
        if (tasks.isEmpty) {
          emit(const FileUploadState.initial());
        } else {
          emit(FileUploadState.uploading(tasks: tasks));
        }
      },
      orElse: () {},
    );
  }

  void _addPendingTask(_PendingUploadTask task) {
    final uploadTask = UploadTask(
      id: task.taskId,
      fileName: task.fileName,
      status: UploadStatus.idle,
      folderId: task.folderId,
    );
    _addOrUpdateTask(uploadTask);

    _retryData[task.taskId] = _TaskRetryData(
      fileBytes: task.fileBytes,
      fileName: task.fileName,
      password: task.password,
      folderId: task.folderId,
      isPublic: task.isPublic,
      onSuccess: task.onSuccess,
    );

    _pendingTasks.add(task);
    _processQueue();
  }

  void _processQueue() {
    if (_isProcessing || _pendingTasks.isEmpty) return;
    _isProcessing = true;
    _executeNextTask();
  }

  Future<void> _executeNextTask() async {
    if (_pendingTasks.isEmpty) {
      _isProcessing = false;
      return;
    }

    final task = _pendingTasks.removeAt(0);
    await _executeTask(task);
    _isProcessing = false;
    _processQueue();
  }

  Future<void> _executeTask(_PendingUploadTask task) async {
    _updateTask(
      UploadTask(
        id: task.taskId,
        fileName: task.fileName,
        status: UploadStatus.idle,
        folderId: task.folderId,
      ),
    );

    try {
      final userId = await authLocalStorage.getUserId();
      if (userId == null) {
        _updateTask(
          UploadTask(
            id: task.taskId,
            fileName: task.fileName,
            status: UploadStatus.error,
            errorMessage: 'Пользователь не авторизован',
            folderId: task.folderId,
          ),
        );
        return;
      }

      final contentHash = _calculateSha256(task.fileBytes);

      final duplicate = await fileRepository.checkDuplicate(
        hash: contentHash,
        isPublic: task.isPublic,
      );

      if (duplicate.exists && duplicate.fileContentId != null) {
        _updateTask(
          UploadTask(
            id: task.taskId,
            fileName: task.fileName,
            status: UploadStatus.linking,
            progress: 0.5,
            folderId: task.folderId,
          ),
        );

        await fileRepository.linkExistingFile(
          fileContentId: duplicate.fileContentId!,
          fileName: task.fileName,
          folderId: task.folderId,
          isPublic: task.isPublic,
        );

        _updateTask(
          UploadTask(
            id: task.taskId,
            fileName: task.fileName,
            status: UploadStatus.completed,
            progress: 1.0,
            folderId: task.folderId,
          ),
        );
        task.onSuccess?.call();
        _removeTask(task.taskId);
        return;
      }

      if (task.isPublic) {
        _updateTask(
          UploadTask(
            id: task.taskId,
            fileName: task.fileName,
            status: UploadStatus.uploading,
            progress: 0.1,
            folderId: task.folderId,
          ),
        );

        await fileRepository.uploadPublicFileFromBytes(
          bytes: task.fileBytes,
          fileName: task.fileName,
          folderId: task.folderId,
          contentHash: contentHash,
          onSendProgress: (sent, total) {
            _updateTask(
              UploadTask(
                id: task.taskId,
                fileName: task.fileName,
                status: UploadStatus.uploading,
                progress: sent / total,
                folderId: task.folderId,
              ),
            );
          },
        );

        _updateTask(
          UploadTask(
            id: task.taskId,
            fileName: task.fileName,
            status: UploadStatus.completed,
            progress: 1.0,
            folderId: task.folderId,
          ),
        );
        task.onSuccess?.call();
        _removeTask(task.taskId);
        return;
      }

      _updateTask(
        UploadTask(
          id: task.taskId,
          fileName: task.fileName,
          status: UploadStatus.encrypting,
          progress: 0.0,
          folderId: task.folderId,
        ),
      );

      const keyOwner = 'user';

      String userPublicKeyPem;
      if (kIsWeb) {
        userPublicKeyPem = (await keyManagerService.getUserPublicKey())!;
        if (userPublicKeyPem.isEmpty) {
          throw Exception('Публичный ключ пользователя не найден');
        }
      } else {
        final userPublicKey = await keyManagerService.getUserPublicKeyObject();
        if (userPublicKey == null) {
          throw Exception('Публичный ключ пользователя не найден');
        }
        userPublicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(userPublicKey);
      }

      String userPrivateKeyPem;
      if (kIsWeb) {
        userPrivateKeyPem = (await keyManagerService.getPrivateKeyPEM(
          task.password,
        ))!;
        if (userPrivateKeyPem.isEmpty) {
          throw Exception('Не удалось получить приватный ключ');
        }
      } else {
        final privateKey = await keyManagerService.getPrivateKey(task.password);
        if (privateKey == null) {
          throw Exception('Не удалось получить приватный ключ');
        }
        userPrivateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);
      }

      Uint8List encryptedBytes;
      if (kIsWeb) {
        encryptedBytes = await ShirmEncryptionServiceWeb.encryptBytes(
          task.fileBytes,
          publicKeyPem: userPublicKeyPem,
          userId: userId,
          keyOwner: keyOwner,
          privateKeyPem: userPrivateKeyPem,
          originalFileName: task.fileName,
        );
      } else {
        final tempDir = io.Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempInputPath = '${tempDir.path}/input_$timestamp.bin';

        try {
          await io.File(tempInputPath).writeAsBytes(task.fileBytes);

          final bytesBuilder = BytesBuilder(copy: false);
          final stream = ShirmCrypto.encryptFileStream(
            inputPath: tempInputPath,
            publicKeyPem: userPublicKeyPem,
            privateKeyPem: userPrivateKeyPem,
            userId: userId,
            keyOwner: keyOwner,
            originalFileName: task.fileName,
            compress: true,
          );

          await for (final chunk in stream) {
            bytesBuilder.add(chunk);
          }
          encryptedBytes = bytesBuilder.takeBytes();
        } finally {
          await _deleteTempFile(tempInputPath);
        }
      }

      _updateTask(
        UploadTask(
          id: task.taskId,
          fileName: task.fileName,
          status: UploadStatus.uploading,
          progress: 0.2,
          folderId: task.folderId,
        ),
      );

      final randomName = _generateRandomFileName();
      await fileRepository.uploadShps(
        encryptedData: encryptedBytes,
        originalFileName: randomName,
        folderId: task.folderId,
        userId: userId,
        keyOwner: keyOwner,
        isPublic: task.isPublic,
        contentHash: contentHash,
        onSendProgress: (sent, total) {
          final uploadProgress = 0.2 + (sent / total) * 0.8;
          _updateTask(
            UploadTask(
              id: task.taskId,
              fileName: task.fileName,
              status: UploadStatus.uploading,
              progress: uploadProgress,
              folderId: task.folderId,
            ),
          );
        },
      );

      _updateTask(
        UploadTask(
          id: task.taskId,
          fileName: task.fileName,
          status: UploadStatus.completed,
          progress: 1.0,
          folderId: task.folderId,
        ),
      );
      task.onSuccess?.call();
      _removeTask(task.taskId);
    } catch (e) {
      _updateTask(
        UploadTask(
          id: task.taskId,
          fileName: task.fileName,
          status: UploadStatus.error,
          errorMessage: e.toString(),
          folderId: task.folderId,
        ),
      );
    }
  }

  Future<void> _deleteTempFile(String? path) async {
    if (path != null && !kIsWeb) {
      try {
        final f = io.File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  void _addOrUpdateTask(UploadTask task) {
    final current = state;
    List<UploadTask> tasks = [];
    if (current is _Uploading) {
      tasks = List.from(current.tasks);
    } else if (current is _UploadError) {
      tasks = List.from(current.tasks);
    }

    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }

    if (tasks.isEmpty) {
      emit(const FileUploadState.initial());
    } else {
      emit(FileUploadState.uploading(tasks: tasks));
    }
  }

  void _updateTask(UploadTask task) {
    _addOrUpdateTask(task);
  }

  void _removeTask(String taskId) {
    final current = state;
    List<UploadTask> tasks = [];
    if (current is _Uploading) {
      tasks = List.from(current.tasks);
    } else if (current is _UploadError) {
      tasks = List.from(current.tasks);
    }
    tasks.removeWhere((t) => t.id == taskId);

    _retryData.remove(taskId);

    if (tasks.isEmpty) {
      emit(const FileUploadState.initial());
    } else {
      emit(FileUploadState.uploading(tasks: tasks));
    }
  }

  static String _generateRandomFileName({int length = 16}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
