class DecryptionMetadata {
  final String? presignedUrl;
  final String? encryptedKey;
  final String? iv;
  final int originalSize;
  final String? mimeType;
  final String? fileName;

  DecryptionMetadata({
    this.presignedUrl,
    this.encryptedKey,
    this.iv,
    required this.originalSize,
    this.mimeType,
    this.fileName,
  });

  factory DecryptionMetadata.fromJson(Map<String, dynamic> json) {
    return DecryptionMetadata(
      presignedUrl: json['presignedUrl'] as String?,
      encryptedKey: json['encryptedKey'] as String?,
      iv: json['iv'] as String?,
      originalSize: json['originalSize'] as int,
      mimeType: json['mimeType'] as String?,
      fileName: json['fileName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (presignedUrl != null) 'presignedUrl': presignedUrl,
    if (encryptedKey != null) 'encryptedKey': encryptedKey,
    if (iv != null) 'iv': iv,
    'originalSize': originalSize,
    if (mimeType != null) 'mimeType': mimeType,
    if (fileName != null) 'fileName': fileName,
  };
}
