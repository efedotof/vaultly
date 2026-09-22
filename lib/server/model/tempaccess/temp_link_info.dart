class TempLinkInfo {
  final String fileName;
  final DateTime expiresAt;
  final String mimeType;
  final bool hasPassword;

  TempLinkInfo({
    required this.fileName,
    required this.expiresAt,
    required this.mimeType,
    required this.hasPassword,
  });

  factory TempLinkInfo.fromJson(Map<String, dynamic> json) {
    return TempLinkInfo(
      fileName: json['fileName'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      mimeType: json['mimeType'] as String,
      hasPassword: json['hasPassword'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'expiresAt': expiresAt.toIso8601String(),
    'mimeType': mimeType,
    'hasPassword': hasPassword,
  };

  TempLinkInfo copyWith({
    String? fileName,
    DateTime? expiresAt,
    String? mimeType,
    bool? hasPassword,
  }) {
    return TempLinkInfo(
      fileName: fileName ?? this.fileName,
      expiresAt: expiresAt ?? this.expiresAt,
      mimeType: mimeType ?? this.mimeType,
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }
}
