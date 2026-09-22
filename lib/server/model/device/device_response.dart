class DeviceResponse {
  final String? id;
  final String? uniqueId;
  final String? deviceName;
  final String? deviceType;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;

  DeviceResponse({
    this.id,
    this.uniqueId,
    this.deviceName,
    this.deviceType,
    this.isActive,
    this.createdAt,
    this.lastUsedAt,
  });

  factory DeviceResponse.fromJson(Map<String, dynamic> json) {
    return DeviceResponse(
      id: json['id'] as String?,
      uniqueId: json['uniqueId'] as String?,
      deviceName: json['deviceName'] as String?,
      deviceType: json['deviceType'] as String?,
      isActive: json['isActive'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (uniqueId != null) 'uniqueId': uniqueId,
    if (deviceName != null) 'deviceName': deviceName,
    if (deviceType != null) 'deviceType': deviceType,
    if (isActive != null) 'isActive': isActive,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (lastUsedAt != null) 'lastUsedAt': lastUsedAt!.toIso8601String(),
  };

  DeviceResponse copyWith({
    String? id,
    String? uniqueId,
    String? deviceName,
    String? deviceType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return DeviceResponse(
      id: id ?? this.id,
      uniqueId: uniqueId ?? this.uniqueId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
