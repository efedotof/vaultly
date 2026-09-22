import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    String? accessToken,
    String? refreshToken,
    required String userId,
    String? email,
    required String username,
    required int storageUsed,
    required int storageLimit,
    required Set<String> roles,
    bool? totpEnabled,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}
