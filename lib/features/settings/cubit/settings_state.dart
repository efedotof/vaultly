part of 'settings_cubit.dart';

@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState.initial() = _Initial;
  const factory SettingsState.loading() = _Loading;
  const factory SettingsState.loaded({
    required UserProfileDto profile,
    required List<DeviceResponse> devices,
    @Default(0) int cacheSizeBytes,
  }) = _Loaded;
  const factory SettingsState.error(String message) = _Error;
  const factory SettingsState.loggedOut() = _LoggedOut;
}
