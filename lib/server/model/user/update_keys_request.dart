class UpdateKeysRequest {
  final String publicKey;
  final String privateKeyEncrypted;
  final String currentPassword;

  UpdateKeysRequest({
    required this.publicKey,
    required this.privateKeyEncrypted,
    required this.currentPassword,
  });

  factory UpdateKeysRequest.fromJson(Map<String, dynamic> json) {
    return UpdateKeysRequest(
      publicKey: json['publicKey'] as String,
      privateKeyEncrypted: json['privateKeyEncrypted'] as String,
      currentPassword: json['currentPassword'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'publicKey': publicKey,
    'privateKeyEncrypted': privateKeyEncrypted,
    'currentPassword': currentPassword,
  };
}
