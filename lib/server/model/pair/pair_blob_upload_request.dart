class PairBlobUploadRequest {
  final String responderPublicKey;
  final String responderAlgorithm;
  final String blobCiphertext; // Base64(AES-GCM ciphertext+tag)
  final String blobNonce; // Base64(12-byte IV)
  final String blobAlgorithm;

  PairBlobUploadRequest({
    required this.responderPublicKey,
    required this.responderAlgorithm,
    required this.blobCiphertext,
    required this.blobNonce,
    required this.blobAlgorithm,
  });

  factory PairBlobUploadRequest.fromJson(Map<String, dynamic> json) {
    return PairBlobUploadRequest(
      responderPublicKey: json['responderPublicKey'] as String,
      responderAlgorithm: json['responderAlgorithm'] as String,
      blobCiphertext: json['blobCiphertext'] as String,
      blobNonce: json['blobNonce'] as String,
      blobAlgorithm: json['blobAlgorithm'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'responderPublicKey': responderPublicKey,
      'responderAlgorithm': responderAlgorithm,
      'blobCiphertext': blobCiphertext,
      'blobNonce': blobNonce,
      'blobAlgorithm': blobAlgorithm,
    };
  }
}
