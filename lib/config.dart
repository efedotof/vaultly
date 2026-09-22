import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Config extends GetxController {
  static const _kBaseUrl = 'cfg_base_url';
  static const _kServerPath = 'cfg_server_path';
  static const _kAuthPath = 'cfg_auth_path';
  static const _kDevicePath = 'cfg_device_path';
  static const _kFilePath = 'cfg_file_path';
  static const _kFolderPath = 'cfg_folder_path';
  static const _kUserPath = 'cfg_user_path';
  static const _kTempAccessPath = 'cfg_temp_access_path';
  static const _kGithubRepoUrl = 'cfg_github_repo_url';
  static const _kAppArchiveUrl = 'cfg_app_archive_url';

  static const _defaultBaseUrl = 'https://vaultly.mnapp.ru:4443';
  static const _defaultServerPath = '/api/server-key';
  static const _defaultAuthPath = '/api/auth';
  static const _defaultDevicePath = '/api/device';
  static const _defaultFilePath = '/api/files';
  static const _defaultFolderPath = '/api/folders';
  static const _defaultUserPath = '/api/users';
  static const _defaultTempAccessPath = '/tempacces/version132';
  static const _defaultGithubRepoUrl =
      'https://github.com/efedotof/vaultly.git';
  static const _defaultAppArchiveUrl =
      'https://github.com/efedotof/vaultly/releases/latest/download/app-archive.json';

  final RxString _baseUrl = _defaultBaseUrl.obs;
  final RxString _serverPath = _defaultServerPath.obs;
  final RxString _authPath = _defaultAuthPath.obs;
  final RxString _devicePath = _defaultDevicePath.obs;
  final RxString _filePath = _defaultFilePath.obs;
  final RxString _folderPath = _defaultFolderPath.obs;
  final RxString _userPath = _defaultUserPath.obs;
  final RxString _tempAccessPath = _defaultTempAccessPath.obs;
  final RxString _githubRepoUrl = _defaultGithubRepoUrl.obs;
  final RxString _appArchiveUrl = _defaultAppArchiveUrl.obs;

  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    _baseUrl.value = _prefs!.getString(_kBaseUrl) ?? _defaultBaseUrl;
    _serverPath.value = _prefs!.getString(_kServerPath) ?? _defaultServerPath;
    _authPath.value = _prefs!.getString(_kAuthPath) ?? _defaultAuthPath;
    _devicePath.value = _prefs!.getString(_kDevicePath) ?? _defaultDevicePath;
    _filePath.value = _prefs!.getString(_kFilePath) ?? _defaultFilePath;
    _folderPath.value = _prefs!.getString(_kFolderPath) ?? _defaultFolderPath;
    _userPath.value = _prefs!.getString(_kUserPath) ?? _defaultUserPath;
    _tempAccessPath.value =
        _prefs!.getString(_kTempAccessPath) ?? _defaultTempAccessPath;
    _githubRepoUrl.value =
        _prefs!.getString(_kGithubRepoUrl) ?? _defaultGithubRepoUrl;
    _appArchiveUrl.value =
        _prefs!.getString(_kAppArchiveUrl) ?? _defaultAppArchiveUrl;
  }

  String get baseUrl => _baseUrl.value;
  String get serverPath => _serverPath.value;
  String get authPath => _authPath.value;
  String get devicePath => _devicePath.value;
  String get filePath => _filePath.value;
  String get folderPath => _folderPath.value;
  String get userPath => _userPath.value;
  String get tempAccessPath => _tempAccessPath.value;
  String get githubRepoUrl => _githubRepoUrl.value;
  String get appArchiveUrl => _appArchiveUrl.value;

  String get serverUrl => _join(_baseUrl.value, _serverPath.value);
  String get authUrl => _join(_baseUrl.value, _authPath.value);
  String get deviceUrl => _join(_baseUrl.value, _devicePath.value);
  String get fileUrl => _join(_baseUrl.value, _filePath.value);
  String get folderUrl => _join(_baseUrl.value, _folderPath.value);
  String get userUrl => _join(_baseUrl.value, _userPath.value);
  String get tempAccessUrl => _join(_baseUrl.value, _tempAccessPath.value);

  String _join(String base, String path) {
    if (base.endsWith('/') && path.startsWith('/')) {
      return base.substring(0, base.length - 1) + path;
    }
    if (!base.endsWith('/') && !path.startsWith('/')) {
      return '$base/$path';
    }
    return '$base$path';
  }

  set baseUrl(String v) {
    _baseUrl.value = v;
    _prefs?.setString(_kBaseUrl, v);
  }

  set serverPath(String v) {
    _serverPath.value = v;
    _prefs?.setString(_kServerPath, v);
  }

  set authPath(String v) {
    _authPath.value = v;
    _prefs?.setString(_kAuthPath, v);
  }

  set devicePath(String v) {
    _devicePath.value = v;
    _prefs?.setString(_kDevicePath, v);
  }

  set filePath(String v) {
    _filePath.value = v;
    _prefs?.setString(_kFilePath, v);
  }

  set folderPath(String v) {
    _folderPath.value = v;
    _prefs?.setString(_kFolderPath, v);
  }

  set userPath(String v) {
    _userPath.value = v;
    _prefs?.setString(_kUserPath, v);
  }

  set tempAccessPath(String v) {
    _tempAccessPath.value = v;
    _prefs?.setString(_kTempAccessPath, v);
  }

  set githubRepoUrl(String v) {
    _githubRepoUrl.value = v;
    _prefs?.setString(_kGithubRepoUrl, v);
  }

  set appArchiveUrl(String v) {
    _appArchiveUrl.value = v;
    _prefs?.setString(_kAppArchiveUrl, v);
  }

  Future<void> resetToDefaults() async {
    baseUrl = _defaultBaseUrl;
    serverPath = _defaultServerPath;
    authPath = _defaultAuthPath;
    devicePath = _defaultDevicePath;
    filePath = _defaultFilePath;
    folderPath = _defaultFolderPath;
    userPath = _defaultUserPath;
    tempAccessPath = _defaultTempAccessPath;
    githubRepoUrl = _defaultGithubRepoUrl;
    appArchiveUrl = _defaultAppArchiveUrl;
    await _prefs?.reload();
  }

  Future<void> clearAll() async {
    await _prefs?.clear();
    _baseUrl.value = _defaultBaseUrl;
    _serverPath.value = _defaultServerPath;
    _authPath.value = _defaultAuthPath;
    _devicePath.value = _defaultDevicePath;
    _filePath.value = _defaultFilePath;
    _folderPath.value = _defaultFolderPath;
    _userPath.value = _defaultUserPath;
    _tempAccessPath.value = _defaultTempAccessPath;
    _githubRepoUrl.value = _defaultGithubRepoUrl;
    _appArchiveUrl.value = _defaultAppArchiveUrl;
  }
}
