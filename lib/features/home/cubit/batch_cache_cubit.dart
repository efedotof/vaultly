import 'package:bloc/bloc.dart';
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
    if (files.isEmpty) {
      emit(const BatchCacheState.completed(cachedCount: 0, total: 0));
      return;
    }

    final pwd = password ?? authCubit.currentPassword;
    if (pwd == null || pwd.isEmpty) {
      emit(const BatchCacheState.error('Пароль не указан'));
      return;
    }

    emit(BatchCacheState.inProgress(current: 0, total: files.length));

    int cached = 0;
    int failed = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        await decryptionService.decryptAndCache(file: file, password: pwd);
        cached++;
      } catch (e, stack) {
        failed++;
        _logger.error(
          '[BatchCacheCubit] Ошибка кэширования файла ${file.id}',
          error: e,
          stackTrace: stack,
        );
      }
      emit(BatchCacheState.inProgress(current: i + 1, total: files.length));
      await Future.delayed(Duration.zero);
    }

    if (failed > 0) {
      emit(
        BatchCacheState.error(
          'Кэшировано $cached из ${files.length} файлов. Ошибок: $failed',
        ),
      );
    } else {
      emit(BatchCacheState.completed(cachedCount: cached, total: files.length));
    }
  }
}
