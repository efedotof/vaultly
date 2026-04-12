import 'package:freezed_annotation/freezed_annotation.dart';
part 'register_request.freezed.dart';
part 'register_request.g.dart';

@freezed
abstract class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String publicKey,
    required String privateKeyEncrypted,
    required String salt,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}
