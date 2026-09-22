class DeviceUpdateRequest {
  final String? deviceName;
  final bool? isActive;

  DeviceUpdateRequest({this.deviceName, this.isActive});

  factory DeviceUpdateRequest.fromJson(Map<String, dynamic> json) {
    return DeviceUpdateRequest(
      deviceName: json['deviceName'] as String?,
      isActive: json['isActive'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (deviceName != null) 'deviceName': deviceName,
    if (isActive != null) 'isActive': isActive,
  };
}
