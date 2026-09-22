part of 'batch_cache_cubit.dart';

@freezed
class BatchCacheState with _$BatchCacheState {
  const factory BatchCacheState.initial() = _Initial;
  const factory BatchCacheState.inProgress({
    required int current,
    required int total,
  }) = _InProgress;
  const factory BatchCacheState.completed({
    required int cachedCount,
    required int total,
  }) = _Completed;
  const factory BatchCacheState.error(String message) = _Error;
}
