import 'dart:convert';
import 'package:get/get.dart';
import 'package:vaulth_app/config.dart';
import 'package:vaulth_app/server/model/auth/auth_info.dart';
import 'package:vaulth_app/server/service/logger/logger.dart';

class ApiResponse {
  final int statusCode;
  final dynamic body;

  ApiResponse(this.statusCode, this.body);

  bool get isOk => statusCode >= 200 && statusCode < 300;
}

class ApiClient {
  final GetConnect _connect;

  ApiClient({required Config config, GetConnect? connect})
    : _connect = connect ?? GetConnect() {
    _connect.httpClient.baseUrl = config.baseUrl;
    _connect.httpClient.timeout = const Duration(seconds: 30);
    _connect.httpClient.defaultContentType = 'application/json';

    _connect.httpClient.addRequestModifier<dynamic>((request) {
      final token = AuthInfo().authResponse?.accessToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      return request;
    });

    _connect.httpClient.addResponseModifier((request, response) {
      Logger.d(
        '${request.method} ${request.url} → ${response.statusCode}',
        tag: 'ApiClient',
      );
      return response;
    });
  }

  Future<ApiResponse> get(String path, {Map<String, String>? query}) async {
    final resp = await _connect.get(path, query: query);
    return ApiResponse(resp.statusCode ?? 0, resp.body);
  }

  Future<ApiResponse> post(String path, Map<String, dynamic> body) async {
    final resp = await _connect.post(path, body);
    return ApiResponse(resp.statusCode ?? 0, resp.body);
  }

  Future<ApiResponse> put(String path, Map<String, dynamic> body) async {
    final resp = await _connect.put(path, body);
    return ApiResponse(resp.statusCode ?? 0, resp.body);
  }

  Future<ApiResponse> delete(String path) async {
    final resp = await _connect.delete(path);
    return ApiResponse(resp.statusCode ?? 0, resp.body);
  }

  Map<String, dynamic> jsonMap(dynamic body) {
    if (body == null) return {};
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    if (body is String && body.isNotEmpty) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    return {};
  }
}
