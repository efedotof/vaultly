class DeviceRegisterRequest {
  final String deviceName;
  final String uniqueId;
  final String? deviceType;
  final String? publicKey;
  final String? encryptedPrivateKey;

  DeviceRegisterRequest({
    required this.deviceName,
    required this.uniqueId,
    this.deviceType,
    this.publicKey,
    this.encryptedPrivateKey,
  });

  factory DeviceRegisterRequest.fromJson(Map<String, dynamic> json) {
    return DeviceRegisterRequest(
      deviceName: json['deviceName'] as String,
      uniqueId: json['uniqueId'] as String,
      deviceType: json['deviceType'] as String?,
      publicKey: json['publicKey'] as String?,
      encryptedPrivateKey: json['encryptedPrivateKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceName': deviceName,
    'uniqueId': uniqueId,
    if (deviceType != null) 'deviceType': deviceType,
    if (publicKey != null) 'publicKey': publicKey,
    if (encryptedPrivateKey != null) 'encryptedPrivateKey': encryptedPrivateKey,
  };
}
