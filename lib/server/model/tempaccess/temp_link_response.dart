class TempLinkResponse {
  final String token;
  final String accessUrl;
  final DateTime expiresAt;
  final int? maxDownloads;
  final int? downloadsCount;

  TempLinkResponse({
    required this.token,
    required this.accessUrl,
    required this.expiresAt,
    this.maxDownloads,
    this.downloadsCount,
  });

  factory TempLinkResponse.fromJson(Map<String, dynamic> json) {
    return TempLinkResponse(
      token: json['token'] as String,
      accessUrl: json['accessUrl'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      maxDownloads: json['maxDownloads'] as int?,
      downloadsCount: json['downloadsCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'accessUrl': accessUrl,
    'expiresAt': expiresAt.toIso8601String(),
    'maxDownloads': maxDownloads,
    'downloadsCount': downloadsCount,
  };
}
