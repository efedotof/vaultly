import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/api_client.dart';
import 'package:vaulth_app/server/exception/auth_error_exception.dart';
import 'package:vaulth_app/server/exception/not_found_exception.dart';
import 'package:vaulth_app/server/exception/rate_limit_exception.dart';
import 'package:vaulth_app/server/exception/unknown_error_exception.dart';
import 'package:vaulth_app/server/exception/validation_error_exception.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

import 'device_pairing_interface.dart';
import 'package:vaulth_app/server/model/pair/pair_blob_response.dart';
import 'package:vaulth_app/server/model/pair/pair_blob_upload_request.dart';
import 'package:vaulth_app/server/model/pair/pair_info_response.dart';
import 'package:vaulth_app/server/model/pair/pair_init_request.dart';
import 'package:vaulth_app/server/model/pair/pair_init_response.dart';

class DevicePairingRepository implements DevicePairingInterface {
  final ApiClient _apiClient;
  final Config _config;

  DevicePairingRepository({
    required ApiClient apiClient,
    required Config config,
  })  : _apiClient = apiClient,
        _config = config;

  @override //post
  Future<PairInitResponse> init({required PairInitRequest request}) async {
    try {
      final resp = await _apiClient.post(
        '${_config.pairingPath}/init',
        request.toJson(),
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return PairInitResponse.fromJson(resp.body);

        case 400:
          throw ValidationErrorException("Неправильный формат!");
        case 401:
          throw AuthErrorException();
        case 429:
          throw RateLimitException();
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "DevicePairingRepository: init");
      throw UnknownErrorException();
    }
  }

  @override //get
  Future<PairInfoResponse> getInfo({required String pairingId}) async {
    try {
      final resp = await _apiClient.get(
        '${_config.pairingPath}/$pairingId',
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return PairInfoResponse.fromJson(resp.body);

        case 400:
          throw ValidationErrorException("Неправильный формат!");
        case 401:
          throw AuthErrorException();
        case 404:
          throw NotFoundException("Pairing не найден или истёк");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "DevicePairingRepository: getInfo");
      throw UnknownErrorException();
    }
  }

  @override //put
  Future<void> uploadBlob({
    required String pairingId,
    required PairBlobUploadRequest request,
  }) async {
    try {
      final resp = await _apiClient.put(
        '${_config.pairingPath}/$pairingId/blob',
        request.toJson(),
      );

      switch (resp.statusCode) {
        case 200:
          return;

        case 400:
          throw ValidationErrorException("Неправильный формат!");
        case 401:
          throw AuthErrorException();
        case 404:
          throw NotFoundException("Pairing не найден или истёк");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "DevicePairingRepository: uploadBlob");
      throw UnknownErrorException();
    }
  }

  @override //get
  Future<PairBlobResponse> fetchBlob({required String pairingId}) async {
    try {
      final resp = await _apiClient.get(
        '${_config.pairingPath}/$pairingId/blob',
      );

      switch (resp.statusCode) {
        case 200:
          if (resp.body == null || resp.body == "") throw UnknownErrorException();
          return PairBlobResponse.fromJson(resp.body);

        case 400:
          throw ValidationErrorException("Неправильный формат!");
        case 401:
          throw AuthErrorException();
        case 404:
          throw NotFoundException("Blob не найден или pairing истёк");
        case 500:
          throw UnknownErrorException();

        default:
          throw UnknownErrorException();
      }
    } catch (e) {
      Logger.d("error: $e", tag: "DevicePairingRepository: fetchBlob");
      throw UnknownErrorException();
    }
  }
}