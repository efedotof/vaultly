import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute, debugPrint;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vaulth_app/server/model/file/upload_task/upload_task.dart';
import 'package:vaulth_app/server/repository/file/file_interface.dart';
import 'package:vaulth_app/server/service/shirm_encryption_service.dart';
import 'package:vaulth_app/server/service/shirm_encryption_service_web.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

part 'file_upload_state.dart';
part 'file_upload_cubit.freezed.dart';

class _EncryptParams {
  final String inputPath;
  final String outputPath;
  final String publicKeyPem;
  final String privateKeyPem;
  final String userId;
  final String keyOwner;

  _EncryptParams({
    required this.inputPath,
    required this.outputPath,
    required this.publicKeyPem,
    required this.privateKeyPem,
    required this.userId,
    required this.keyOwner,
  });
}

Future<void> _encryptFileInIsolate(_EncryptParams params) async {
  final inputFile = File(params.inputPath);
  final outputFile = File(params.outputPath);

  final publicKey = CryptoUtils.rsaPublicKeyFromPem(params.publicKeyPem);
  final privateKey = CryptoUtils.rsaPrivateKeyFromPem(params.privateKeyPem);

  final encryptedBytes = await ShirmEncryptionService.encryptFile(
    inputFile,
    publicKey: publicKey,
    userId: params.userId,
    keyOwner: params.keyOwner,
    privateKey: privateKey,
  );

  await outputFile.writeAsBytes(encryptedBytes);
}

class _TaskRetryData {
  final Uint8List fileBytes;
  final String fileName;
  final String password;
  final String? folderId;
  final bool isPublic;
  final VoidCallback? onSuccess;

  _TaskRetryData({
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

  FileUploadCubit({
    required this.fileRepository,
    required this.keyManagerService,
    required this.authLocalStorage,
  }) : super(const FileUploadState.initial());

  Future<void> addUploadTask({
    required Uint8List fileBytes,
    required String fileName,
    required String password,
    String? folderId,
    required bool isPublic,
    VoidCallback? onSuccess,
  }) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final task = UploadTask(
      id: taskId,
      fileName: fileName,
      status: UploadStatus.idle,
      folderId: folderId,
    );

    _retryData[taskId] = _TaskRetryData(
      fileBytes: fileBytes,
      fileName: fileName,
      password: password,
      folderId: folderId,
      isPublic: isPublic,
      onSuccess: onSuccess,
    );

    _addOrUpdateTask(task);

    String? tempEncryptedPath;
    String? tempInputPath;

    try {
      final userId = await authLocalStorage.getUserId();
      if (userId == null) {
        _updateTask(
          task.copyWith(
            status: UploadStatus.error,
            errorMessage: 'Пользователь не авторизован',
          ),
        );
        return;
      }

      if (isPublic) {
        _updateTask(
          task.copyWith(status: UploadStatus.uploading, progress: 0.1),
        );

        if (kIsWeb) {
          await fileRepository.uploadPublicFileFromBytes(
            bytes: fileBytes,
            fileName: fileName,
            folderId: folderId,
            onSendProgress: (sent, total) {
              _updateTask(task.copyWith(progress: sent / total));
            },
          );
        } else {
          final tempDir = await getTemporaryDirectory();
          if (!await tempDir.exists()) {
            await tempDir.create(recursive: true);
          }
          final tempFile = File('${tempDir.path}/upload_$fileName');
          await tempFile.writeAsBytes(fileBytes);
          try {
            await fileRepository.uploadPublicFile(
              file: tempFile,
              folderId: folderId,
              onSendProgress: (sent, total) {
                _updateTask(task.copyWith(progress: sent / total));
              },
            );
          } finally {
            await tempFile.delete();
          }
        }

        _updateTask(
          task.copyWith(status: UploadStatus.completed, progress: 1.0),
        );
        onSuccess?.call();
        _removeTask(taskId);
        return;
      }

      _updateTask(
        task.copyWith(status: UploadStatus.encrypting, progress: 0.0),
      );

      final keyOwner = 'user';

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
          password,
        ))!;
        if (userPrivateKeyPem.isEmpty) {
          throw Exception('Не удалось получить приватный ключ');
        }
      } else {
        final privateKey = await keyManagerService.getPrivateKey(password);
        if (privateKey == null) {
          throw Exception('Не удалось получить приватный ключ');
        }
        userPrivateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);
      }

      Uint8List encryptedBytes;
      if (kIsWeb) {
        encryptedBytes = await ShirmEncryptionServiceWeb.encryptBytes(
          fileBytes,
          publicKeyPem: userPublicKeyPem,
          userId: userId,
          keyOwner: keyOwner,
          privateKeyPem: userPrivateKeyPem,
          originalFileName: fileName,
        );
      } else {
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        tempInputPath = '${tempDir.path}/input_$timestamp.bin';
        tempEncryptedPath = '${tempDir.path}/encrypted_$timestamp.shps';

        await File(tempInputPath).writeAsBytes(fileBytes);

        await compute(
          _encryptFileInIsolate,
          _EncryptParams(
            inputPath: tempInputPath,
            outputPath: tempEncryptedPath,
            publicKeyPem: userPublicKeyPem,
            privateKeyPem: userPrivateKeyPem,
            userId: userId,
            keyOwner: keyOwner,
          ),
        );

        final encryptedFile = File(tempEncryptedPath);
        encryptedBytes = await encryptedFile.readAsBytes();
      }

      _updateTask(task.copyWith(status: UploadStatus.uploading, progress: 0.2));

      final randomName = _generateRandomFileName();
      await fileRepository.uploadShps(
        encryptedData: encryptedBytes,
        originalFileName: randomName,
        folderId: folderId,
        userId: userId,
        keyOwner: keyOwner,
        isPublic: isPublic,
        onSendProgress: (sent, total) {
          final uploadProgress = 0.2 + (sent / total) * 0.8;
          _updateTask(task.copyWith(progress: uploadProgress));
        },
      );

      _updateTask(task.copyWith(status: UploadStatus.completed, progress: 1.0));
      onSuccess?.call();
      _removeTask(taskId);
    } catch (e, stackTrace) {
      debugPrint('Upload error: $e\n$stackTrace');
      _updateTask(
        task.copyWith(status: UploadStatus.error, errorMessage: e.toString()),
      );
    } finally {
      if (!kIsWeb) {
        await _deleteTempFile(tempEncryptedPath);
        await _deleteTempFile(tempInputPath);
      }
    }
  }

  Future<void> retryTask(String taskId) async {
    final data = _retryData[taskId];
    if (data == null) return;

    dismissTask(taskId);
    _retryData.remove(taskId);

    await addUploadTask(
      fileBytes: data.fileBytes,
      fileName: data.fileName,
      password: data.password,
      folderId: data.folderId,
      isPublic: data.isPublic,
      onSuccess: data.onSuccess,
    );
  }

  void dismissTask(String taskId) {
    _removeTask(taskId);
  }

  Future<void> _deleteTempFile(String? path) async {
    if (path != null) {
      try {
        final f = File(path);
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
