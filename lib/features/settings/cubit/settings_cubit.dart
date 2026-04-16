import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vaulth_app/features/auth/cubit/auth_cubit.dart';
import 'package:vaulth_app/server/model/device/device_register_request/device_register_request.dart';
import 'package:vaulth_app/server/model/device/device_response/device_response.dart';
import 'package:vaulth_app/server/model/device/device_update_request/device_update_request.dart';
import 'package:vaulth_app/server/model/totp/totp_disable_request/totp_disable_request.dart';
import 'package:vaulth_app/server/model/totp/totp_setup_response/totp_setup_response.dart';
import 'package:vaulth_app/server/model/totp/totp_verify_request/totp_verify_request.dart';
import 'package:vaulth_app/server/model/user/update_keys_request/update_keys_request.dart';
import 'package:vaulth_app/server/model/user/update_recovery_keys_request/update_recovery_keys_request.dart';
import 'package:vaulth_app/server/model/user/user_profile_dto/user_profile_dto.dart';
import 'package:vaulth_app/server/repository/auth/auth_interface.dart';
import 'package:vaulth_app/server/repository/device/device_interface.dart';
import 'package:vaulth_app/server/repository/totp/totp_interface.dart';
import 'package:vaulth_app/server/repository/user/user_interface.dart';
import 'package:vaulth_app/server/service/local_file_cache.dart';
import 'package:vaulth_app/server/service/seed_phrase_service.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

part 'settings_state.dart';
part 'settings_cubit.freezed.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final UserInterface userRepository;
  final AuthInterface authRepository;
  final DeviceInterface deviceRepository;
  final dynamic keyManager;
  final LocalFileCache fileCache;
  final AuthLocalStorage authStorage;
  final AuthCubit authCubit;
  final TotpInterface totpInterface;
  final SeedPhraseService seedPhraseService;
  SettingsCubit({
    required this.userRepository,
    required this.authRepository,
    required this.deviceRepository,
    required this.keyManager,
    required this.fileCache,
    required this.authStorage,
    required this.authCubit,
    required this.totpInterface,
    required this.seedPhraseService,
  }) : super(const SettingsState.initial());

  TotpSetupResponse? _pendingTotpSetup;

  Future<void> loadSettingsData() async {
    emit(const SettingsState.loading());
    try {
      final profile = await userRepository.getCurrentUserProfile();
      final devices = await deviceRepository.getUserDevices();
      final cacheSize = await fileCache.getCacheSize();
      emit(
        SettingsState.loaded(
          profile: profile,
          devices: devices,
          cacheSizeBytes: cacheSize,
        ),
      );
    } catch (e) {
      if (_is403Error(e)) {
        emit(SettingsState.unauthorized());
        return;
      }
      emit(SettingsState.error(e.toString()));
    }
  }

  Future<void> logout() async {
    await authCubit.logout(manual: true);
  }

  Future<String?> getPrivateKey(String password) async {
    try {
      return await keyManager.getPrivateKeyPEM(password);
    } catch (e) {
      if (_is403Error(e)) {
        emit(SettingsState.unauthorized());
      }
      emit(SettingsState.error('Не удалось получить приватный ключ: $e'));
      return null;
    }
  }

  Future<String?> getPublicKey() async {
    return await keyManager.getPublicKey();
  }

  Future<void> registerDevice(DeviceRegisterRequest request) async {
    final previousState = state;
    _emitLoadingOrLoading(previousState);
    try {
      await deviceRepository.registerDevice(request);
      await refreshDevices();
    } catch (e) {
      if (_is403Error(e)) {
        emit(SettingsState.unauthorized());
        return;
      }
      _emitErrorAndRestore(e.toString(), previousState);
    }
  }

  Future<void> updateDevice(
    String deviceId,
    DeviceUpdateRequest request,
  ) async {
    final previousState = state;
    _emitLoadingOrLoading(previousState);
    try {
      await deviceRepository.updateDevice(deviceId, request);
      await refreshDevices();
    } catch (e) {
      if (_is403Error(e)) {
        emit(SettingsState.unauthorized());
        return;
      }
      _emitErrorAndRestore(e.toString(), previousState);
    }
  }

  Future<void> deactivateDevice(String deviceId) async {
    final previousState = state;
    _emitLoadingOrLoading(previousState);
    try {
      await deviceRepository.deactivateDevice(deviceId);
      await refreshDevices();
    } catch (e) {
      if (_is403Error(e)) {
        emit(SettingsState.unauthorized());
        return;
      }
      _emitErrorAndRestore(e.toString(), previousState);
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    final previousState = state;
    _emitLoadingOrLoading(previousState);
    try {
      await deviceRepository.deleteDevice(deviceId);
      await refreshDevices();
    } catch (e) {
      if (_is403Error(e)) {
        emit(SettingsState.unauthorized());
        return;
      }
      _emitErrorAndRestore(e.toString(), previousState);
    }
  }

  Future<void> refreshDevices() async {
    await state.maybeWhen(
      loaded: (profile, devices, cacheSize) async {
        try {
          final newDevices = await deviceRepository.getUserDevices();
          emit(
            SettingsState.loaded(
              profile: profile,
              devices: newDevices,
              cacheSizeBytes: cacheSize,
            ),
          );
        } catch (e) {
          if (_is403Error(e)) {
            emit(SettingsState.unauthorized());
            return;
          }
          emit(SettingsState.error('Ошибка обновления устройств: $e'));
          emit(state);
        }
      },
      orElse: () => loadSettingsData(),
    );
  }

  Future<void> refreshProfile() async {
    await state.maybeWhen(
      loaded: (profile, devices, cacheSize) async {
        try {
          final newProfile = await userRepository.getCurrentUserProfile();
          emit(
            SettingsState.loaded(
              profile: newProfile,
              devices: devices,
              cacheSizeBytes: cacheSize,
            ),
          );
        } catch (e) {
          if (_is403Error(e)) {
            emit(SettingsState.unauthorized());
            return;
          }
          emit(SettingsState.error('Ошибка обновления профиля: $e'));
          emit(state);
        }
      },
      orElse: () => loadSettingsData(),
    );
  }

  Future<void> clearCache() async {
    final previousState = state;
    try {
      await fileCache.clearCache();
      await state.maybeWhen(
        loaded: (profile, devices, _) async {
          emit(
            SettingsState.loaded(
              profile: profile,
              devices: devices,
              cacheSizeBytes: 0,
            ),
          );
        },
        orElse: () {},
      );
    } catch (e) {
      if (_is403Error(e)) {
        emit(SettingsState.unauthorized());
        return;
      }
      emit(SettingsState.error('Ошибка очистки кэша: $e'));
      if (previousState is _Loaded) {
        emit(previousState);
      }
    }
  }

  Future<void> refreshCacheSize() async {
    await state.maybeWhen(
      loaded: (profile, devices, _) async {
        try {
          final cacheSize = await fileCache.getCacheSize();
          emit(
            SettingsState.loaded(
              profile: profile,
              devices: devices,
              cacheSizeBytes: cacheSize,
            ),
          );
        } catch (e) {
          if (_is403Error(e)) {
            emit(SettingsState.unauthorized());
            return;
          }
        }
      },
      orElse: () {},
    );
  }

  void _emitLoadingOrLoading(SettingsState previousState) {
    previousState.maybeWhen(
      loaded: (_, _, _) => emit(const SettingsState.loading()),
      orElse: () => emit(const SettingsState.loading()),
    );
  }

  Future<void> clearAllKeys() async {
    await keyManager.clearAllKeys();
  }

  Future<String?> getDevicePublicKey() async {
    return await keyManager.getDevicePublicKey();
  }

  Future<String?> getDevicePrivateKeyPEM(String password) async {
    try {
      return await keyManager.getDevicePrivateKeyPEM(password);
    } catch (e) {
      if (_is403Error(e)) {
        emit(SettingsState.unauthorized());
      }
      emit(
        SettingsState.error(
          'Не удалось получить приватный ключ устройства: $e',
        ),
      );
      return null;
    }
  }

  void _emitErrorAndRestore(String message, SettingsState previousState) {
    emit(SettingsState.error(message));
    previousState.maybeWhen(
      loaded: (profile, devices, cacheSize) => emit(
        SettingsState.loaded(
          profile: profile,
          devices: devices,
          cacheSizeBytes: cacheSize,
        ),
      ),
      orElse: () => emit(const SettingsState.initial()),
    );
  }

  Future<void> startTotpSetup() async {
    final previousState = state;
    try {
      emit(const SettingsState.totpSetupLoading());
      final response = await totpInterface.setupTotp();
      _pendingTotpSetup = response;
      emit(SettingsState.totpSetupReady(response.qrCodeUrl, response.secret));
    } catch (e) {
      if (_is403Error(e)) {
        emit(SettingsState.unauthorized());
        return;
      }
      emit(SettingsState.error('Ошибка настройки TOTP: $e'));
      _restoreState(previousState);
    }
  }

  Future<void> verifyAndEnableTotp(String code) async {
    if (_pendingTotpSetup == null) {
      emit(const SettingsState.error('Нет активной настройки TOTP'));
      return;
    }
    final previousState = state;
    try {
      emit(const SettingsState.totpVerifying());
      final request = TotpVerifyRequest(code: code);
      final response = await totpInterface.verifyTotp(request);
      await refreshProfile();
      emit(SettingsState.totpEnabled(response.backupCodes));
    } catch (e) {
      if (_is403Error(e)) {
        emit(SettingsState.unauthorized());
        return;
      }
      emit(SettingsState.error('Неверный код: $e'));
      _restoreState(previousState);
    }
  }

  Future<void> disableTotp(String code) async {
    final previousState = state;
    try {
      emit(const SettingsState.totpDisabling());
      final request = TotpDisableRequest(code: code);
      await totpInterface.disableTotp(request);
      await refreshProfile();
      emit(const SettingsState.totpDisabled());
    } catch (e) {
      if (_is403Error(e)) {
        emit(SettingsState.unauthorized());
        return;
      }
      emit(SettingsState.error('Ошибка отключения TOTP: $e'));
      _restoreState(previousState);
    }
  }

  void _restoreState(SettingsState previousState) {
    previousState.maybeWhen(
      loaded: (profile, devices, cacheSize) => emit(
        SettingsState.loaded(
          profile: profile,
          devices: devices,
          cacheSizeBytes: cacheSize,
        ),
      ),
      orElse: () => emit(const SettingsState.initial()),
    );
  }

  void resetTotpStates() {
    _pendingTotpSetup = null;
    state.maybeWhen(
      loaded: (profile, devices, cacheSize) => emit(
        SettingsState.loaded(
          profile: profile,
          devices: devices,
          cacheSizeBytes: cacheSize,
        ),
      ),
      orElse: () {},
    );
  }

  Future<void> generateAndUpdateSeedPhrase(String password) async {
    emit(const SettingsState.seedGenerating());
    try {
      final rsaPrivateKeyPem = await keyManager.getPrivateKeyPEM(password);
      if (rsaPrivateKeyPem == null) {
        throw Exception('Неверный пароль или данные повреждены');
      }

      final currentSalt = await keyManager.getUserSalt();
      if (currentSalt == null) {
        throw Exception('Соль не найдена');
      }

      await keyManager.storeUserPrivateKeyEncryptedWithPassword(
        rsaPrivateKeyPem,
        password,
        salt: currentSalt,
      );

      final encryptedPrivateKey = await keyManager
          .getUserEncryptedPrivateKeyData();
      if (encryptedPrivateKey == null) {
        throw Exception('Не удалось получить зашифрованный приватный ключ');
      }

      final publicKey = await keyManager.getUserPublicKey();
      if (publicKey == null || publicKey.isEmpty) {
        throw Exception('Публичный ключ не найден');
      }

      final updateKeysRequest = UpdateKeysRequest(
        publicKey: publicKey,
        privateKeyEncrypted: encryptedPrivateKey,
        currentPassword: password,
      );
      await userRepository.updateKeys(request: updateKeysRequest);

      final mnemonic = SeedPhraseService.generateMnemonic();
      final seed = SeedPhraseService.mnemonicToSeed(mnemonic);
      final edKeyPair = await SeedPhraseService.deriveEd25519KeyPair(seed);

      final encryptedEdPrivateKey = await keyManager.encryptWithPassword(
        edKeyPair.privateKeyBase64,
        password,
      );

      final encryptedRsaKey = await SeedPhraseService.encryptRsaKeyWithMnemonic(
        rsaPrivateKeyPem,
        mnemonic,
      );

      emit(const SettingsState.seedUpdating());
      final recoveryRequest = UpdateRecoveryKeysRequest(
        recoveryPublicKey: edKeyPair.publicKeyBase64,
        recoveryPrivateKeyEncrypted: encryptedEdPrivateKey,
        recoveryEncryptedRsaKey: encryptedRsaKey,
        currentPassword: password,
      );
      await userRepository.updateRecoveryKeys(request: recoveryRequest);

      final words = mnemonic.split(' ');
      emit(SettingsState.seedReady(mnemonic, words));
    } catch (e) {
      if (_is403Error(e)) {
        emit(SettingsState.unauthorized());
        return;
      }
      emit(SettingsState.error('Ошибка создания seed-фразы: $e'));
      await loadSettingsData();
    }
  }

  bool _is403Error(Object e) {
    final errorString = e.toString();
    return errorString.contains('403') ||
        errorString.contains('status code of 403') ||
        (e is Exception && errorString.contains('Network error'));
  }
}
