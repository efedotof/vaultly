class PairInfoResponse {
  final String pairingId;
  final String initiatorPublicKey;
  final String initiatorAlgorithm;
  final DateTime expiresAt;
  final bool blobAlreadySet;

  PairInfoResponse({
    required this.pairingId,
    required this.initiatorPublicKey,
    required this.initiatorAlgorithm,
    required this.expiresAt,
    required this.blobAlreadySet,
  });

  factory PairInfoResponse.fromJson(Map<String, dynamic> json) {
    return PairInfoResponse(
      pairingId: json['pairingId'] as String,
      initiatorPublicKey: json['initiatorPublicKey'] as String,
      initiatorAlgorithm: json['initiatorAlgorithm'] as String,
      expiresAt: json['expiresAt'] as DateTime,
      blobAlreadySet: ['blobAlreadySet'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pairingId': pairingId,
      'initiatorPublicKey': initiatorPublicKey,
      'initiatorAlgorithm': initiatorAlgorithm,
      'expiresAt': expiresAt,
      'blobAlreadySet': blobAlreadySet,
    };
  }
}
