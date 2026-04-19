import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vaulth_app/features/auth/cubit/auth_cubit.dart';
import 'package:vaulth_app/server/model/file/file_dto/file_dto.dart';
import 'package:vaulth_app/server/service/file_decryption_service.dart';
import 'package:vaulth_app/server/service/logger_service.dart';

part 'batch_cache_state.dart';
part 'batch_cache_cubit.freezed.dart';

class BatchCacheCubit extends Cubit<BatchCacheState> {
  final FileDecryptionService decryptionService;
  final AuthCubit authCubit;
  final LoggerService _logger = LoggerService();

  BatchCacheCubit({required this.decryptionService, required this.authCubit})
    : super(const BatchCacheState.initial());

  Future<void> cacheAllFiles(List<FileDto> files, {String? password}) async {
    debugPrint(
      '[BatchCacheCubit] cacheAllFiles called with ${files.length} files',
    );
    if (files.isEmpty) {
      debugPrint(
        '[BatchCacheCubit] No files to cache, emitting completed(0,0)',
      );
      emit(const BatchCacheState.completed(cachedCount: 0, total: 0));
      return;
    }

    final pwd = password ?? authCubit.currentPassword;
    if (pwd == null || pwd.isEmpty) {
      debugPrint('[BatchCacheCubit] Password is empty, emitting error');
      emit(const BatchCacheState.error('Пароль не указан'));
      return;
    }
    debugPrint('[BatchCacheCubit] Password obtained, starting batch cache');

    emit(BatchCacheState.inProgress(current: 0, total: files.length));
    debugPrint('[BatchCacheCubit] State: inProgress (0/${files.length})');

    int cached = 0;
    int failed = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      debugPrint(
        '[BatchCacheCubit] Processing file ${i + 1}/${files.length}: id=${file.id}, name=${file.originalName}, isPublic=${file.isPublic}',
      );
      try {
        await decryptionService.decryptAndCache(file: file, password: pwd);
        cached++;
        debugPrint('[BatchCacheCubit] Successfully cached file ${file.id}');
      } catch (e, stack) {
        failed++;
        debugPrint('[BatchCacheCubit] Failed to cache file ${file.id}: $e');
        _logger.error(
          '[BatchCacheCubit] Ошибка кэширования файла ${file.id}',
          error: e,
          stackTrace: stack,
        );
      }
      await Future.delayed(Duration.zero);
      emit(BatchCacheState.inProgress(current: i + 1, total: files.length));
      debugPrint(
        '[BatchCacheCubit] State: inProgress (${i + 1}/${files.length})',
      );
    }

    if (failed > 0) {
      debugPrint(
        '[BatchCacheCubit] Batch cache finished with errors: $cached succeeded, $failed failed',
      );
      emit(
        BatchCacheState.error(
          'Кэшировано $cached из ${files.length} файлов. Ошибок: $failed',
        ),
      );
    } else {
      debugPrint(
        '[BatchCacheCubit] Batch cache completed successfully: $cached files cached',
      );
      emit(BatchCacheState.completed(cachedCount: cached, total: files.length));
    }
  }
}
