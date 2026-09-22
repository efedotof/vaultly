class CreateTempLinkRequest {
  final String fileId;
  final DateTime expiresAt;
  final int? maxDownloads;
  final String? password;

  CreateTempLinkRequest({
    required this.fileId,
    required this.expiresAt,
    this.maxDownloads,
    this.password,
  });

  factory CreateTempLinkRequest.fromJson(Map<String, dynamic> json) {
    return CreateTempLinkRequest(
      fileId: json['fileId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      maxDownloads: json['maxDownloads'] as int?,
      password: json['password'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'expiresAt': expiresAt.toIso8601String(),
    if (maxDownloads != null) 'maxDownloads': maxDownloads,
    if (password != null) 'password': password,
  };
}
