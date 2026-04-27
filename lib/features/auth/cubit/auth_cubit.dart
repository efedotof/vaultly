import 'dart:async';
import 'dart:io';
import 'package:basic_utils/basic_utils.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:vaulth_app/server/model/auth/auth_response/auth_response.dart';
import 'package:vaulth_app/server/model/auth/login_request/login_request.dart';
import 'package:vaulth_app/server/model/auth/logout_request/logout_request.dart';
import 'package:vaulth_app/server/model/auth/recover_request/recover_request.dart';
import 'package:vaulth_app/server/model/auth/register_request/register_request.dart';
import 'package:vaulth_app/server/model/auth/token_validation_request/token_validation_request.dart';
import 'package:vaulth_app/server/model/device/device_register_request/device_register_request.dart';
import 'package:vaulth_app/server/model/user/update_keys_request/update_keys_request.dart';
import 'package:vaulth_app/server/repository/auth/auth_interface.dart';
import 'package:vaulth_app/server/repository/auth/auth_repository.dart';
import 'package:vaulth_app/server/repository/device/device_interface.dart';
import 'package:vaulth_app/server/repository/user/user_interface.dart';
import 'package:vaulth_app/server/service/key/device_id_generator.dart';
import 'package:vaulth_app/server/service/system/logger_service.dart';
import 'package:vaulth_app/server/service/key/seed_phrase_service.dart';
import 'package:vaulth_app/server/service/update/update_service.dart';
import 'package:vaulth_app/storage/auth_local_storage.dart';

part 'auth_state.dart';
part 'auth_cubit.freezed.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthInterface authRepository,
    required DeviceInterface deviceRepository,
    required dynamic keyManagerService,
    required AuthLocalStorage authLocalService,
    required UserInterface userInterface,
    required UpdateService updateService,
  }) : _userInterface = userInterface,
       _authinterface = authRepository,
       _deviceInterface = deviceRepository,
       _keyManagerService = keyManagerService,
       _authLocalStorage = authLocalService,
       _updateService = updateService,
       super(const AuthState.loading()) {
    Future.microtask(() => checkAuthStatus());
  }

  final AuthInterface _authinterface;
  final DeviceInterface _deviceInterface;
  final dynamic _keyManagerService;
  final AuthLocalStorage _authLocalStorage;
  final UserInterface _userInterface;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final DeviceIdGenerator _deviceIdGenerator = DeviceIdGenerator();
  final UpdateService _updateService;
  String? _currentPassword;
  String? get currentPassword => _currentPassword;

  Future<String> _getDeviceType() async {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isFuchsia) return 'fuchsia';
    return 'unknown';
  }

  Future<String> _getDeviceName() async {
    try {
      if (kIsWeb) {
        final info = await _deviceInfo.webBrowserInfo;
        return info.userAgent ?? 'Web Browser';
      }
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.name;
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return windowsInfo.computerName;
      } else if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfo.macOsInfo;
        return macOsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return linuxInfo.name;
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      LoggerService().warning('AuthCubit: failed to get device name', error: e);
      return 'Device';
    }
  }

  Future<void> register({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    LoggerService().debug(
      'AuthCubit: register started for username: $username',
    );
    try {
      emit(const AuthState.loading());

      final publicKeyPEM = await _keyManagerService.generateAndStoreUserKeyPair(
        password,
      );
      if (publicKeyPEM.isEmpty) {
        throw Exception('Failed to generate user key pair');
      }

      final encryptedPrivateKey = await _keyManagerService
          .getUserEncryptedPrivateKeyData();
      final salt = await _keyManagerService.getUserSalt();

      if (encryptedPrivateKey == null || salt == null) {
        throw Exception('Failed to retrieve encrypted private key or salt');
      }

      final request = RegisterRequest(
        username: username,
        password: password,
        firstName: firstName,
        lastName: lastName,
        publicKey: publicKeyPEM,
        privateKeyEncrypted: encryptedPrivateKey,
        salt: salt,
      );
      final response = await _authinterface.register(request);
      await _authLocalStorage.saveAuthData(response);

      await registerDevice(authResponse: response, userPassword: password);
    } catch (e) {
      LoggerService().error('AuthCubit: registration error', error: e);
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> login({
    required String username,
    required String password,
    String? totpCode,
  }) async {
    emit(const AuthState.loading());
    try {
      final request = LoginRequest(
        username: username,
        password: password,
        totpCode: totpCode,
      );
      final response = await _authinterface.login(request);
      await _authLocalStorage.saveAuthData(response);
      _currentPassword = password;
      await _authLocalStorage.savePassword(password);

      final hasLocalUserKey =
          await _keyManagerService.getUserPublicKey() != null;
      if (!hasLocalUserKey) {
        final encryptedKey = await _userInterface.getUserEncryptedPrivateKey();
        final salt = await _userInterface.getUserSalt();

        final privateKeyPem = await _keyManagerService
            .decryptPrivateKeyWithPassword(encryptedKey, salt, password);
        if (privateKeyPem == null) {
          throw Exception('Неверный пароль или данные повреждены');
        }

        await _keyManagerService.storeUserPrivateKeyEncryptedWithPassword(
          privateKeyPem,
          password,
        );

        final profile = await _userInterface.getCurrentUserProfile();
        final publicKeyPem = profile.publicKey;
        if (publicKeyPem == null || publicKeyPem.isEmpty) {
          throw Exception('Публичный ключ пользователя не найден в профиле');
        }
        await _keyManagerService.saveUserPublicKey(publicKeyPem);
      }

      try {
        await registerDevice(authResponse: response, userPassword: password);
      } catch (e) {
        LoggerService().warning('Device registration postponed', error: e);
      }

      emit(AuthState.authenticated(response));
    } on TotpRequiredException catch (_) {
      LoggerService().info('AuthCubit: TOTP required for $username');
      emit(AuthState.totpRequired(username: username, password: password));
    } catch (e) {
      LoggerService().error('AuthCubit: login error', error: e);
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> registerDevice({
    String? deviceName,
    String? deviceType,
    required AuthResponse authResponse,
    required String userPassword,
  }) async {
    try {
      final effectiveDeviceName = deviceName ?? await _getDeviceName();
      final effectiveDeviceType = deviceType ?? await _getDeviceType();
      final uniqueDeviceId = await _deviceIdGenerator.generateDeviceId();

      final existingDevices = await _deviceInterface.getUserDevices();
      final alreadyExists = existingDevices.any(
        (d) => d.uniqueId == uniqueDeviceId,
      );

      if (alreadyExists) {
        LoggerService().debug(
          'Device already registered, skipping registration',
        );

        emit(AuthState.authenticated(authResponse));
        return;
      }

      emit(const AuthState.loading());

      String devicePublicKeyPem;
      try {
        if (await _keyManagerService.hasDeviceKeys()) {
          devicePublicKeyPem = (await _keyManagerService.getDevicePublicKey())!;
        } else {
          devicePublicKeyPem = await _keyManagerService
              .generateAndStoreDeviceKeyPair(userPassword);
          await _authLocalStorage.savePassword(userPassword);
        }
      } catch (e, stack) {
        LoggerService().error(
          'Failed to obtain device key pair',
          error: e,
          stackTrace: stack,
        );
        emit(AuthState.error('Ошибка генерации ключей устройства: $e'));
        return;
      }

      String userPrivateKeyPem;
      if (kIsWeb) {
        userPrivateKeyPem = (await _keyManagerService.getPrivateKeyPEM(
          userPassword,
        ))!;
        if (userPrivateKeyPem.isEmpty) {
          throw Exception('Не удалось получить приватный ключ пользователя');
        }
      } else {
        final userPrivateKey = await _keyManagerService.getPrivateKey(
          userPassword,
        );
        if (userPrivateKey == null) {
          throw Exception('Не удалось получить приватный ключ пользователя');
        }
        userPrivateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(
          userPrivateKey,
        );
      }

      String encryptedForDevice;
      if (kIsWeb) {
        encryptedForDevice = await _keyManagerService
            .hybridEncryptWithPublicKeyPem(
              userPrivateKeyPem,
              devicePublicKeyPem,
            );
      } else {
        final devicePublicKey = CryptoUtils.rsaPublicKeyFromPem(
          devicePublicKeyPem,
        );
        encryptedForDevice = await _keyManagerService
            .hybridEncryptWithPublicKey(userPrivateKeyPem, devicePublicKey);
      }

      final request = DeviceRegisterRequest(
        deviceName: effectiveDeviceName,
        deviceType: effectiveDeviceType,
        publicKey: devicePublicKeyPem,
        encryptedPrivateKey: encryptedForDevice,
        uniqueId: uniqueDeviceId,
      );

      await _deviceInterface.registerDevice(request);
      emit(AuthState.authenticated(authResponse));
    } catch (e, stack) {
      LoggerService().error(
        'Device registration failed',
        error: e,
        stackTrace: stack,
      );
      emit(AuthState.error('Ошибка регистрации устройства: $e'));
    }
  }

  Future<void> logout({bool manual = false}) async {
    LoggerService().debug('AuthCubit: logout started, manual: $manual');
    try {
      emit(const AuthState.loading());

      final token = await _authLocalStorage.getAccessToken();
      if (token != null) {
        try {
          LoggerService().debug('AuthCubit: sending logout request...');
          await _authinterface.logout(LogoutRequest(token: token));
        } catch (e) {
          LoggerService().warning('AuthCubit: server logout error', error: e);
          if (!manual) {
            await _authLocalStorage.clearAuthData();
            _currentPassword = null;
            emit(const AuthState.unauthenticated());
            return;
          }
        }
      } else {
        LoggerService().debug('AuthCubit: no access token found for logout');
      }

      await _authLocalStorage.clearAuthData();
      _currentPassword = null;

      if (manual) {
        await _keyManagerService.clearUserKeys();
        LoggerService().debug(
          'AuthCubit: user keys cleared, device keys preserved (manual logout)',
        );
      }

      LoggerService().debug(
        'AuthCubit: logout completed, state unauthenticated',
      );
      emit(const AuthState.unauthenticated());
    } catch (e) {
      LoggerService().error(
        'AuthCubit: logout error, clearing data according to manual=$manual',
        error: e,
      );
      if (manual) {
        await _authLocalStorage.clearAuthData();
        await _keyManagerService.clearUserKeys();
      } else {
        await _authLocalStorage.clearAuthData();
      }
      _currentPassword = null;
      emit(const AuthState.unauthenticated());
    }
  }

  Future<bool> _attemptAutoLogin(String username, String password) async {
    try {
      final request = LoginRequest(username: username, password: password);
      final response = await _authinterface.login(request);
      await _authLocalStorage.saveAuthData(response);
      _currentPassword = password;
      await _authLocalStorage.savePassword(password);

      final hasLocalUserKey =
          await _keyManagerService.getUserPublicKey() != null;
      if (!hasLocalUserKey) {
        final encryptedKey = await _userInterface.getUserEncryptedPrivateKey();
        final salt = await _userInterface.getUserSalt();
        final privateKeyPem = await _keyManagerService
            .decryptPrivateKeyWithPassword(encryptedKey, salt, password);
        if (privateKeyPem == null) {
          throw Exception('Invalid password or corrupted data');
        }
        await _keyManagerService.storeUserPrivateKeyEncryptedWithPassword(
          privateKeyPem,
          password,
        );
        final profile = await _userInterface.getCurrentUserProfile();
        final publicKeyPem = profile.publicKey;
        if (publicKeyPem == null || publicKeyPem.isEmpty) {
          throw Exception('User public key not found in profile');
        }
        await _keyManagerService.saveUserPublicKey(publicKeyPem);
      }

      try {
        await registerDevice(authResponse: response, userPassword: password);
      } catch (e) {
        LoggerService().warning(
          'Device registration postponed during auto-login',
          error: e,
        );
      }

      return true;
    } catch (e) {
      LoggerService().error('Auto-login attempt failed', error: e);
      return false;
    }
  }

  Future<void> checkAuthStatus() async {
    LoggerService().debug('AuthCubit: checkAuthStatus started');

    try {
      final token = await _authLocalStorage.getAccessToken();
      if (token == null) {
        LoggerService().debug(
          'AuthCubit: no access token found, unauthenticated',
        );
        emit(const AuthState.unauthenticated());
        return;
      }

      try {
        final validationRequest = TokenValidationRequest(token: token);
        final response = await _authinterface.validateToken(validationRequest);

        final userPublicKey = await _keyManagerService.getUserPublicKey();
        if (userPublicKey == null) {
          LoggerService().warning(
            'AuthCubit: user public key missing, need auto-login',
          );
          throw Exception('User public key missing');
        }

        await _authLocalStorage.saveAuthData(response);

        final savedPassword = await _authLocalStorage.getPassword();
        if (savedPassword != null) {
          final privateKey = await _keyManagerService.getPrivateKey(
            savedPassword,
          );
          if (privateKey != null) {
            _currentPassword = savedPassword;
            LoggerService().debug('AuthCubit: password restored from storage');
          } else {
            await _authLocalStorage.deletePassword();
            LoggerService().debug(
              'AuthCubit: stored password invalid, removed',
            );
          }
        }
        unawaited(_updateService.checkForUpdate());
        LoggerService().debug('AuthCubit: token valid, user authenticated');
        emit(AuthState.authenticated(response));
        return;
      } catch (validationError) {
        LoggerService().warning(
          'AuthCubit: token validation failed, attempting auto-login',
          error: validationError,
        );
      }

      final savedAuth = await _authLocalStorage.loadAuthData();
      final savedPassword = await _authLocalStorage.getPassword();

      if (savedAuth != null && savedPassword != null) {
        final success = await _attemptAutoLogin(
          savedAuth.username,
          savedPassword,
        );
        if (success) {
          final freshAuth = await _authLocalStorage.loadAuthData();
          if (freshAuth != null) {
            emit(AuthState.authenticated(freshAuth));
            return;
          }
        }
        LoggerService().debug('AuthCubit: auto-login failed, cleaning up');
      }

      await _authLocalStorage.clearAuthData();
      await _keyManagerService.clearUserKeys();
      _currentPassword = null;
      emit(const AuthState.unauthenticated());
    } catch (e) {
      LoggerService().error(
        'AuthCubit: checkAuthStatus unexpected error, falling back to unauthenticated',
        error: e,
      );
      await _authLocalStorage.clearAuthData();
      await _keyManagerService.clearUserKeys();
      _currentPassword = null;
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> recoverAccess({
    required String mnemonic,
    required String newPassword,
  }) async {
    emit(const AuthState.loading());
    try {
      final seed = SeedPhraseService.mnemonicToSeed(mnemonic);
      final keyPair = await SeedPhraseService.deriveEd25519KeyPair(seed);

      final authRequest = RecoverRequest(publicKey: keyPair.publicKeyBase64);
      final authResponse = await _authinterface.recoverAccess(
        request: authRequest,
      );

      final token = authResponse.accessToken;
      if (token == null) {
        throw Exception('Server did not return access token');
      }

      await _authLocalStorage.saveAuthData(authResponse);
      _authinterface.setAccessToken(token);

      final recoveryData = await _userInterface.getRecoveryData();

      final rsaPrivateKeyPem =
          await SeedPhraseService.decryptRsaKeyWithMnemonic(
            recoveryData.recoveryEncryptedRsaKey,
            mnemonic,
          );

      final serverSalt = await _userInterface.getUserSalt();
      if (serverSalt.isEmpty) {
        throw Exception('Не удалось получить соль с сервера');
      }

      await _keyManagerService.storeUserPrivateKeyEncryptedWithPassword(
        rsaPrivateKeyPem,
        newPassword,
        salt: serverSalt,
      );
      _currentPassword = newPassword;
      await _authLocalStorage.savePassword(newPassword);

      final profile = await _userInterface.getCurrentUserProfile();
      final publicKeyPem = profile.publicKey;
      if (publicKeyPem == null || publicKeyPem.isEmpty) {
        throw Exception('Публичный ключ пользователя не найден в профиле');
      }
      await _keyManagerService.saveUserPublicKey(publicKeyPem);

      final encryptedRsaForServer = await _keyManagerService
          .encryptWithPassword(rsaPrivateKeyPem, newPassword);
      final updateKeysRequest = UpdateKeysRequest(
        publicKey: publicKeyPem,
        privateKeyEncrypted: encryptedRsaForServer,
        currentPassword: newPassword,
      );
      await _userInterface.updateKeys(request: updateKeysRequest);

      try {
        await registerDevice(
          authResponse: authResponse,
          userPassword: newPassword,
        );
      } catch (e) {
        LoggerService().warning('Device registration postponed', error: e);
      }

      emit(AuthState.authenticated(authResponse));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  void setCurrentPassword(String password) {
    _currentPassword = password;
  }

  void resetToUnauthenticated() => emit(const AuthState.unauthenticated());
}
