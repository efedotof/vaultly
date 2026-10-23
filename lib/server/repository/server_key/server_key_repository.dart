import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/api_client.dart';
import 'package:vaulth_app/server/exception/auth_error_exception.dart';
import 'package:vaulth_app/server/exception/unknown_error_exception.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

import 'server_key_interface.dart';

class ServerKeyRepository implements ServerKeyInterface {
  final ApiClient _apiClient;
  final Config _config;

  ServerKeyRepository({required ApiClient apiClient, required Config config})
      : _apiClient = apiClient,
        _config = config;

  String get _base => _config.serverPath;

  @override
  Future<String> getServerPublicKey() async {
    try {
      final resp = await _apiClient.get('$_base/public');

      switch (resp.statusCode) {
        case 200:
          final body = resp.body;
          if (body == null) throw UnknownErrorException();

          final pem = body is String ? body : body.toString();
          if (pem.isEmpty || !pem.contains('BEGIN PUBLIC KEY')) {
            throw UnknownErrorException();
          }
          return pem;

        case 401:
          throw AuthErrorException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "ServerKeyRepository: getServerPublicKey");
      throw UnknownErrorException();
    }
  }
}