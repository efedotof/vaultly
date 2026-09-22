class RecoveryDataResponse {
  final String recoveryEncryptedRsaKey;
  final String salt;

  RecoveryDataResponse({
    required this.recoveryEncryptedRsaKey,
    required this.salt,
  });

  factory RecoveryDataResponse.fromJson(Map<String, dynamic> json) {
    return RecoveryDataResponse(
      recoveryEncryptedRsaKey: json['recoveryEncryptedRsaKey'] as String,
      salt: json['salt'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'recoveryEncryptedRsaKey': recoveryEncryptedRsaKey,
    'salt': salt,
  };
}
