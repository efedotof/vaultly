part of 'profile_cubit.dart';

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState.initial() = _Initial;
  const factory ProfileState.loading() = _Loading;
  const factory ProfileState.loaded(UserProfileDto profile) = _Loaded;
  const factory ProfileState.error(String message) = _Error;
  const factory ProfileState.updating() = _Updating;
  const factory ProfileState.updateSuccess(UserProfileDto profile) =
      _UpdateSuccess;
  const factory ProfileState.updateError(String message) = _UpdateError;
}
