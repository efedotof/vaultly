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
  const factory SettingsState.totpSetupLoading() = _TotpSetupLoading;
  const factory SettingsState.totpSetupReady(String qrCodeUrl, String secret) =
      _TotpSetupReady;
  const factory SettingsState.totpVerifying() = _TotpVerifying;
  const factory SettingsState.totpEnabled(List<String> backupCodes) =
      _TotpEnabled;
  const factory SettingsState.totpDisabling() = _TotpDisabling;
  const factory SettingsState.totpDisabled() = _TotpDisabled;
  const factory SettingsState.seedGenerating() = _SeedGenerating;
  const factory SettingsState.seedReady(String mnemonic, List<String> words) =
      _SeedReady;
  const factory SettingsState.seedUpdating() = _SeedUpdating;
  const factory SettingsState.seedUpdated() = _SeedUpdated;
  const factory SettingsState.unauthorized() = _Unauthorized;
}
