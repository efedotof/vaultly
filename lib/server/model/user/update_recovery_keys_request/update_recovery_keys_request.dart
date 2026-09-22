import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_recovery_keys_request.freezed.dart';
part 'update_recovery_keys_request.g.dart';

@freezed
abstract class UpdateRecoveryKeysRequest with _$UpdateRecoveryKeysRequest {
  const factory UpdateRecoveryKeysRequest({
    required String recoveryPublicKey,
    required String recoveryPrivateKeyEncrypted,
    required String recoveryEncryptedRsaKey,
    required String currentPassword,
  }) = _UpdateRecoveryKeysRequest;

  factory UpdateRecoveryKeysRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateRecoveryKeysRequestFromJson(json);
}
