class UpdateRecoveryKeysRequest {
  final String recoveryPublicKey;
  final String recoveryPrivateKeyEncrypted;
  final String recoveryEncryptedRsaKey;
  final String currentPassword;

  UpdateRecoveryKeysRequest({
    required this.recoveryPublicKey,
    required this.recoveryPrivateKeyEncrypted,
    required this.recoveryEncryptedRsaKey,
    required this.currentPassword,
  });

  factory UpdateRecoveryKeysRequest.fromJson(Map<String, dynamic> json) {
    return UpdateRecoveryKeysRequest(
      recoveryPublicKey: json['recoveryPublicKey'] as String,
      recoveryPrivateKeyEncrypted:
          json['recoveryPrivateKeyEncrypted'] as String,
      recoveryEncryptedRsaKey: json['recoveryEncryptedRsaKey'] as String,
      currentPassword: json['currentPassword'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'recoveryPublicKey': recoveryPublicKey,
    'recoveryPrivateKeyEncrypted': recoveryPrivateKeyEncrypted,
    'recoveryEncryptedRsaKey': recoveryEncryptedRsaKey,
    'currentPassword': currentPassword,
  };
}
