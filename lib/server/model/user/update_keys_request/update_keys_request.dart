import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_keys_request.freezed.dart';
part 'update_keys_request.g.dart';

@freezed
abstract class UpdateKeysRequest with _$UpdateKeysRequest {
  const factory UpdateKeysRequest({
    required String publicKey,
    required String privateKeyEncrypted,
    required String currentPassword,
  }) = _UpdateKeysRequest;

  factory UpdateKeysRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateKeysRequestFromJson(json);
}
