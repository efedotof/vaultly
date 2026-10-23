class PairBlobResponse {
  final String pairingId;
  final String responderPublicKey;
  final String responderAlgorithm;
  final String blobCiphertext;
  final String blobNonce;
  final String blobAlgorithm;
  final DateTime expiresAt;

  PairBlobResponse({
    required this.pairingId,
    required this.responderPublicKey,
    required this.responderAlgorithm,
    required this.blobCiphertext,
    required this.blobNonce,
    required this.blobAlgorithm,
    required this.expiresAt,
  });

  factory PairBlobResponse.fromJson(Map<String, dynamic> json) {
    return PairBlobResponse(
      pairingId: json['pairingId'] as String,
      responderPublicKey: json['responderPublicKey'] as String,
      responderAlgorithm: json['responderAlgorithm'] as String,
      blobCiphertext: json['blobCiphertext'] as String,
      blobNonce: json['blobNonce'] as String,
      blobAlgorithm: json['blobAlgorithm'] as String,
      expiresAt: json['expiresAt'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pairingId': pairingId,
      'responderPublicKey': responderPublicKey,
      'responderAlgorithm': responderAlgorithm,
      'blobCiphertext': blobCiphertext,
      'blobNonce': blobNonce,
      'blobAlgorithm': blobAlgorithm,
      'expiresAt': expiresAt,
    };
  }
}
